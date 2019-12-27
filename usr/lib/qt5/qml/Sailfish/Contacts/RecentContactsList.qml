import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0 as Contacts
import org.nemomobile.contacts 1.0
import org.nemomobile.commhistory 1.0

Column {
    id: root

    property alias recentContactsModel: contactsRepeater.model
    property var contactsModel
    property var selectionModel
    property bool menuOpen
    property Item menuItem
    property int count

    signal contactClicked(var delegateItem, var contact)
    signal contactPressed()
    signal contactPressAndHold(var delegateItem, var contact)

    function _updateCount() {
        var c = 0
        for (var i = 0; i < contactsRepeater.count; ++i) {
            var item = contactsRepeater.itemAt(i)
            if (item && item.contentHeight > 0) {
                c++
            }
        }
        count = c
    }

    width: parent.width

    Component.onCompleted: recentContactsModel.getEvents()

    Repeater {
        id: contactsRepeater

        onCountChanged: root._updateCount()

        delegate: Contacts.ContactBrowserItem {
            id: contactItem

            width: root.width

            contactId: eventPerson.id
            peopleModel: contactsModel
            selectionModel: root.selectionModel

            firstText: eventPerson.primaryName
            secondText: eventPerson.secondaryName
            unnamed: eventPerson.primaryName == root.contactsModel.placeholderDisplayLabel
            presenceState: eventPerson.globalPresenceState

            canDeleteContact: false

            readonly property bool isPhone: model.localUid.indexOf('/ring/tel/') >= 0
            readonly property bool isMessage: (model.eventType != CommCallModel.CallEvent) && (model.eventType != CommCallModel.VoicemailEvent)

            property Person eventPerson: Person {
                firstName: ' ' // Non-empty initial string to suppress 'Unnamed'

                Component.onCompleted: {
                    if (isPhone) {
                        phoneDetails = [{
                            'number': model.remoteUid,
                            'type': Person.PhoneNumberType,
                            'index': -1
                        }]
                    } else {
                        accountDetails = [{
                            'accountPath': model.localUid,
                            'accountUri': model.remoteUid,
                            'type': Person.OnlineAccountType,
                            'index': -1
                        }]
                    }
                }
            }

            visible: contentHeight > 0
            contentHeight: {
                if (eventPerson.favorite) {
                    return 0
                }
                if (root.recentContactsModel.requiredProperty != PeopleModel.NoPropertyRequired) {
                    var selectableProperties = getSelectableProperties()
                    if (selectableProperties == undefined || !(selectableProperties.length > 0)) {
                        // If this item is not currently selectable, it should have no height
                        return 0
                    }
                }
                return Theme.itemSizeSmall
            }
            onContentHeightChanged: root._updateCount()

            _backgroundColor: "transparent"
            ContactItemGradient {
                listItem: contactItem
            }
            onMenuOpenChanged: {
                if (menuOpen) {
                    root.menuItem = _menuItem
                } else if (root.menuItem === _menuItem) {
                    root.menuItem = null
                }
                root.menuOpen = menuOpen
            }
            onContactClicked: root.contactClicked(contactItem, contact)

            function getPerson() {
                if (eventPerson.id) {
                    return contactsModel.personById(eventPerson.id)
                }
                return eventPerson
            }

            function getSelectableProperties() {
                if (root.recentContactsModel.requiredProperty != PeopleModel.NoPropertyRequired) {
                    return ContactsUtil.selectableProperties(eventPerson, root.recentContactsModel.requiredProperty, Person)
                }
                return undefined
            }

            onPressed: root.contactPressed()
            onPressAndHold: root.contactPressAndHold(contactItem, getPerson())

            Component.onCompleted: {
                if (isPhone) {
                    eventPerson.resolvePhoneNumber(model.remoteUid, false)
                } else {
                    eventPerson.resolveOnlineAccount(model.localUid, model.remoteUid, false)
                }
            }
        }
    }
}
