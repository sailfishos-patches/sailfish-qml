/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0 as SailfishContacts
import org.nemomobile.contacts 1.0

QtObject {
    id: root

    property var contactCardPage
    property var peopleModel
    property string activeDetail
    readonly property bool busy: _busy

    property var contact

    property var _linkTargetContact
    property int _linkSourceContactId
    property bool _busy
    property bool _autoShowContactPicker
    property var _resolveTarget

    signal savedAsContact(var contact)
    signal resolvedToContact(var contact)
    signal aggregatedIntoContact(var contact)
    signal error(string errorText)

    function selectContactToLink(pageStackAction) {
        if (contactCardPage.status === PageStatus.Active) {
            pageStack.animatorPush(_contactSelectComponent, {}, pageStackAction)
        } else {
            // Show the busy indicator until the contact card page is active, then load the picker
            // immediately without animations.
            _busy = true
            _autoShowContactPicker = true
        }
    }

    function _prepareToLinkTo(linkTargetContact) {
        if (contact == null) {
            console.warn("contact not set!")
            return
        }

        _busy = true
        _linkTargetContact = linkTargetContact

        if (contact.id === 0) {
            peopleModel.savePerson(contact)
        } else {
            _linkSourceContactId = contact.id
            _doLinking()
        }
    }

    function _doLinking() {
        if (_linkSourceContactId === 0) {
            console.warn("Invalid _linkSourceContactId!")
            return
        }

        var linkSourceContact = peopleModel.personById(_linkSourceContactId)
        if (!linkSourceContact.complete) {
            linkSourceContact.completeChanged.connect(_doLinking)
            linkSourceContact.ensureComplete()
            return
        }

        linkSourceContact.completeChanged.disconnect(_doLinking)
        _aggregationOpConn.target = _linkTargetContact
        linkSourceContact.aggregateInto(_linkTargetContact)
    }

    function _resolveUnsavedContact() {
        if (!peopleModel.populated || !contact || contact.id !== 0) {
            return
        }

        var detail
        var resolvedContact

        if (contact.phoneDetails.length) {
            detail = contact.phoneDetails[0].number
            resolvedContact = peopleModel.personByPhoneNumber(detail, true)
            if (resolvedContact) {
                resolvedToContact(resolvedContact)
            } else {
                _delayedContactResolve().resolvePhoneNumber(detail, true)
            }
        } else if (contact.emailDetails.length) {
            detail = contact.emailDetails[0].address
            resolvedContact = peopleModel.personByEmailAddress(detail, true)
            if (resolvedContact) {
                resolvedToContact(resolvedContact)
            } else {
                _delayedContactResolve().resolveEmailAddress(detail, true)
            }
        } else if (contact.accountDetails.length) {
            var localUid = contact.accountDetails[0].accountPath
            detail = contact.accountDetails[0].accountUri
            resolvedContact = peopleModel.personByOnlineAccount(localUid, detail, true)
            if (resolvedContact) {
                resolvedToContact(resolvedContact)
            } else {
                _delayedContactResolve().resolveOnlineAccount(localUid, detail, true)
            }
        }
        if (detail) {
            activeDetail = detail
        }
    }

    function _delayedContactResolve() {
        _resolveTarget = _personComponent.createObject(root)
        _resolveTarget.addressResolved.connect(function() {
            if (_resolveTarget.id !== 0) {
                resolvedToContact(peopleModel.personById(_resolveTarget.id))
            }
            _resolveTarget.destroy()
            _resolveTarget = null
        })
        return _resolveTarget
    }

    Component.onCompleted: {
        // If opening a contact card using a detail (e.g. phone number) rather than a saved contact,
        // try to match the detail to a saved contact.
        _resolveUnsavedContact()
    }

    property var _peopleModelConn: Connections {
        target: root.peopleModel

        onPopulatedChanged: {
            if (root.peopleModel.populated) {
                root._resolveUnsavedContact()
            }
        }

        onSavePersonSucceeded: {
            if (root._busy) {
                root._linkSourceContactId = aggregateId
                root._doLinking()
            } else if (root.contact && root.contact.id === 0) {
                // Contact card was waiting for the result of a save.
                var person = root.peopleModel.personById(aggregateId)
                if (person) {
                    root.savedAsContact(person)
                }
            }
        }

        onSavePersonFailed: {
            if (root._busy) {
                //% "Unable to save contact"
                root.error(qsTrId("components_contacts-la-contact_save_error"))
                root._busy = false
            }
        }
    }

    // Detect when linking completes.
    property var _aggregationOpConn: Connections {
        target: null

        onAggregationOperationFinished: {
            // Contact has been linked; now show the linked contact instead of the original
            // unsaved contact.
            root.aggregatedIntoContact(target)
            target = null
            root._busy = false
        }
    }

    property var _contactPickerPush: Timer {
        property bool wasTriggered

        interval: 0
        onTriggered: {
            wasTriggered = true
            root.selectContactToLink(PageStackAction.Immediate)
        }
    }

    property var _contactCardPageConn: Connections {
        target: root.contactCardPage

        onStatusChanged: {
            if (root.contactCardPage.status === PageStatus.Active && root._autoShowContactPicker) {
                root._autoShowContactPicker = false

                // Delay the pageStack push to avoid page status binding loops.
                _contactPickerPush.start()
            }
        }
    }

    property var _contactSelectComponent: Component {
        ContactSelectPage {
            property bool _contactSelected

            onContactClicked: {
                _contactSelected = true
                root._prepareToLinkTo(contact)
                pageStack.pop()
            }

            onStatusChanged: {
                if (status === PageStatus.Active) {
                    root._busy = true
                } else if (status === PageStatus.Inactive) {
                    if (_contactPickerPush.wasTriggered && !_contactSelected) {
                        // The contact picker was automatically pushed without seeing the previous
                        // contact card page, then rejected, so now it should be automatically
                        // popped so that the previous page is not shown.
                        _delayedPop.start()
                    }
                } else if (status === PageStatus.Deactivating) {
                    if (!_contactPickerPush.wasTriggered && !_contactSelected) {
                        // The contact picker was manually opened from the previous page, then
                        // rejected, so just update the busy status instead of popping again.
                        root._busy = false
                    }
                }
            }
        }
    }

    property var _delayedPop: Timer {
        interval: 0
        onTriggered: {
            pageStack.pop(pageStack.previousPage(root.contactCardPage), PageStackAction.Immediate)
        }
    }

    property var _personComponent: Component {

        Person {}
    }
}
