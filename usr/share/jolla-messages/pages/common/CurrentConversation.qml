import QtQuick 2.6
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0
import org.nemomobile.commhistory 1.0
import Sailfish.Contacts 1.0
import Sailfish.Messages 1.0

Item {
    id: conversation

    // Temporary person instances are created dynamically and a reference is held here
    // Only modify by assignment, to ensure change signals are emitted properly
    property var people: [ ]
    property bool hasPeople: people.length > 0
    property bool hasPhoneNumber
    property string title
    property MessageChannel message: messageChannel
    property QtObject contactGroup
    property bool hasConversation: hasPeople || message.hasChannel || contactGroup !== null
    property bool modelPopulated
    property string recipients: {
        var first = ''
        var multiple = false
        if (contactGroup) {
            first = contactGroup.displayNames[0]
            multiple = contactGroup.displayNames.length > 1
        } else if (hasPeople) {
            first = people[0].displayLabel
            multiple = people.length > 1
        } else if (message.hasChannel) {
            first = message.remoteUids[0]
            multiple = message.remoteUids > 1
        }
        if (first) {
            // Add ellipsis to indicate further recipients, if required
            return first + (multiple ? '\u2026' : '')
        }
        return ''
    }

    // Emitted when the details of contacts in people change, without changing contacts.
    // This happens when completing contacts from the cache, for example.
    signal peopleDetailsChanged
    signal targetChanged

    MessageChannel {
        id: messageChannel
    }

    Connections {
        target: MessageUtils.telepathyAccounts
        onRingAccountPathChanged: {
            // When active SIM changes, update current conversation only
            // if existing message is SMS message.
            // ChatTextInput sets the channel when communication type is changed.
            if (message && message.isSMS) {
                message.updateChannel(MessageUtils.telepathyAccounts.ringAccountPath)
            }
        }
    }

    function clear() {
        _clearPeople()
        message.clear()
        contactGroup = null
    }

    function fromMessageChannel() {
        if (contactGroup && groupMatchesChannel(contactGroup, message))
            return

        contactGroup = _findContactGroup([])
        _updatePeople()

        targetChanged()
        if (MessageUtils.debug) {
            console.debug("CurrentConversation.fromMessageChannel:", message.localUid, message.remoteUids,
                          contactGroup ? contactGroup.groups : contactGroup, people[0].id, people[0].displayLabel)
        }
    }

    function fromContactGroup(newContactGroup) {
        if (newContactGroup === contactGroup)
            return

        contactGroup = newContactGroup
        message.clear()
        _updatePeople()
        _selectDefaultChannel()

        targetChanged()
        if (MessageUtils.debug) {
            console.debug("CurrentConversation.fromContactGroup:", contactGroup, people, message)
        }
    }

    function _findContactGroup(matchPeople) {
        var groups = groupModel.contactGroups
        for (var i = 0; i < groups.length; i++) {
            if ((matchPeople && matchPeople.length && groupMatchesPeople(groups[i], matchPeople))
                || (message.hasChannel && groupMatchesChannel(groups[i], message)))
            {
                return groups[i]
            }
        }

        return null
    }

    Component {
        id: personComponent
        Person {}
    }

    // Return an array of people created from the contact group or channel
    function _getPeople() {
        var localUid
        var remoteUids

        // XXX No way to use contactGroup.contactIds unless all have contacts...

        if (contactGroup) {
            // It's guaranteed that every group in a ContactGroup resolves to the same contacts,
            // or has the same local+remote UIDs if no contact matches, so any can be used.
            var group = contactGroup.groups[0]
            localUid = group.localUid
            remoteUids = group.remoteUids
        } else if (message.hasChannel) {
            localUid = message.localUid
            remoteUids = message.remoteUids
        }

        var result = [ ]
        for (var i = 0; i < remoteUids.length; i++) {
            // Attempt to resolve the contact based on the account; if that fails, use fake details.
            // If the cache is later able to resolve it, the instance will be updated.
            var p = _createPerson()
            if (MessageUtils.isSMS(localUid)) {
                p.resolvePhoneNumber(remoteUids[i], true)
                if (!p.id)
                    _addFakePersonAccounts(p, [ remoteUids[i] ], [ ])
            } else {
                p.resolveOnlineAccount(localUid, remoteUids[i], true)
                if (!p.id)
                    _addFakePersonAccounts(p, [ ], [{ "localUid": localUid, "remoteUid": remoteUids[i] }])
            }
            result.push(p)
        }

        return result
    }

    function _createPerson() {
        return personComponent.createObject(null)
    }

    function _addFakePersonAccounts(person, phoneNumbers, imAccounts) {
        if (phoneNumbers.length) {
            var numbers = person.phoneDetails || []
            for (var i = 0; i < phoneNumbers.length; i++) {
                numbers.push({
                    'type': Person.PhoneNumberType,
                    'number': phoneNumbers[i],
                    'index': -1
                })
            }
            person.phoneDetails = numbers
        }

        if (imAccounts.length) {
            var accounts = person.accountDetails || []
            for (var i = 0; i < imAccounts.length; i++) {
                accounts.push({
                    'type': Person.OnlineAccountType,
                    'accountUri': imAccounts[i].remoteUid,
                    'accountPath': imAccounts[i].localUid,
                    'serviceProvider': MessageUtils.telepathyAccounts.displayName(imAccounts[i].localUid),
                    'index': -1
                })
            }
            person.accountDetails = accounts
        }
    }

    function _selectDefaultChannel() {
        if (contactGroup !== null && contactGroup.lastEventGroup !== null) {
            var group = contactGroup.lastEventGroup
            if (group.remoteUids.length > 1) {
                if (group.localUid == MessageUtils.telepathyAccounts.ringAccountPath) {
                    message.setBroadcastChannel(group.localUid, group.remoteUids, group.id)
                } else {
                    console.log("Cannot select default channel for multi-target group\n")
                    message.clear()
                }
            } else {
                message.setChannel(group.localUid, group.remoteUids[0], group.id)
            }
        } else {
            message.clear()
        }
    }

    function groupMatchesPeople(contactGroup, matchPeople) {
        // We should be able to take any group from the ContactGroup and match it to all people
        var group = contactGroup.groups[0]
        if (!group) {
            return false
        }

        if (!matchPeople.length || group.remoteUids.length != matchPeople.length)
            return false

        var localUid = group.localUid
        var phoneMatch = MessageUtils.isSMS(localUid)

        for (var i = 0; i < matchPeople.length; i++) {
            var remoteUids = []

            if (phoneMatch) {
                var numbers = matchPeople[i].phoneDetails
                for (var j = 0; j < numbers.length; j++) {
                    remoteUids.push(numbers[j].number)
                }
            } else {
                var accounts = matchPeople[i].accountDetails
                for (var j = 0; j < accounts.length; j++) {
                    if (accounts[j].accountPath == localUid) {
                        remoteUids.push(accounts[j].accountUri)
                    }
                }
            }

            if (!group.matchesAnyOf(remoteUids)) {
                // This person is not a member of the group
                return false
            }
        }

        // All members matched
        return true
    }

    function groupMatchesChannel(group, message) {
        if (group.findGroup(message.localUid, message.remoteUids))
            return true
        return false
    }

    function groupIds() {
        var re = []
        var groups = contactGroup ? contactGroup.groups : [ ]
        for (var i = 0; i < groups.length; i++)
            re.push(groups[i].id)
        return re
    }

    Connections {
        target: contactGroup
        onContactsChanged: {
            if (!groupMatchesPeople(contactGroup, people)) {
                // If the group no longer matches person or channel, clear the group and stick
                // to the channel. This may be possible when deleting contacts, for example.
                if (message.hasChannel && !groupMatchesChannel(contactGroup, message)) {
                    contactGroup = _findContactGroup([])
                    _updatePeople()
                    return
                }
            }

            // Update people under the assumptions that contacts were resolved/unresolved
            _updatePeople()
        }
    }

    function _contactGroupChanged(group) {
        if (contactGroup === group)
            return

        // Check if this new/updated contactGroup matches our other properties, even if there's
        // already a group set; this handles channels moving between groups, for example.
        if (hasPeople && groupMatchesPeople(group, people)) {
            contactGroup = group
        } else if (message.hasChannel && groupMatchesChannel(group, message)) {
            contactGroup = group
            _updatePeople()
        }
    }

    Connections {
        target: groupModel

        onContactGroupCreated: _contactGroupChanged(group)
        onContactGroupChanged: _contactGroupChanged(group)
        onContactGroupRemoved: {
            if (group === contactGroup) {
                // Removing current ContactGroup; reset and stay with channel
                contactGroup = _findContactGroup(people)
            }
        }
    }

    Timer {
        id: detailsChangedTimer
        interval: 1
        onTriggered: peopleDetailsChanged()
    }

    function _personChanged() {
        detailsChangedTimer.restart()
    }

    function _personRemoved() {
        // Update people, which will look up a new contact for the removed address
        _updatePeople()
    }

    function _connectPersonSignals(person) {
        if (!person.id)
            person.contactChanged.connect(_personChanged)
        if (!person.complete)
            person.completeChanged.connect(_personChanged)
        person.phoneDetailsChanged.connect(_personChanged)
        person.accountDetailsChanged.connect(_personChanged)
        person.contactRemoved.connect(_personRemoved)
    }

    function _disconnectPersonSignals(person) {
        person.contactChanged.disconnect(_personChanged)
        person.completeChanged.disconnect(_personChanged)
        person.phoneDetailsChanged.disconnect(_personChanged)
        person.accountDetailsChanged.disconnect(_personChanged)
        person.contactRemoved.disconnect(_personRemoved)
    }

    function _destroyPersons(persons) {
        for (var i = 0; i < persons.length; i++) {
            _disconnectPersonSignals(persons[i])
            persons[i].destroy()
        }
    }

    function _clearPeople() {
        _destroyPersons(people)
        people = []
    }

    function _updatePeople() {
        if (!modelPopulated) {
            return
        }
        var old = people.slice()
        var newPeople = _getPeople()
        conversation.title = _conversationTitle(newPeople)
        hasPhoneNumber = _hasPhoneNumber(newPeople)
        people = newPeople
        _destroyPersons(old)
    }

    function _conversationTitle(peopleList) {
        if (peopleList.length === 0) {
            console.warn("peopleList.length is empty, this should NOT happen.")
            return
        }

        if (peopleList.length === 1) {
            return peopleList[0].displayLabel
        }

        var conversationTitle = ""

        for (var i = 0; i < peopleList.length; i++) {
            var person = peopleList[i]
            var shortName = person.firstName || person.lastName || person.displayLabel

            if (shortName) {
                conversationTitle += shortName

                if (i !== (peopleList.length - 1)) {
                    conversationTitle += Format.listSeparator
                }
            }
        }

        return conversationTitle
    }

    function _hasPhoneNumber(peopleList) {
        for (var i = 0; i < peopleList.length; i++) {
            if (peopleList[i].hasValidPhoneNumber()) {
                return true
            }
        }
        return false
    }

    onPeopleChanged: {
        for (var i = 0; i < people.length; i++) {
            _disconnectPersonSignals(people[i])
            _connectPersonSignals(people[i])
        }
    }

    onModelPopulatedChanged: {
        // Update the people list if fromMessageChannel() or fromContactGroup() has been called to
        // set up the conversation.
        if (modelPopulated && (contactGroup || message.hasChannel)) {
            _updatePeople()
        }
    }
}

