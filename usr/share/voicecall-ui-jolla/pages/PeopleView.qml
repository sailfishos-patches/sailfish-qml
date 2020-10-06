/**
 * Copyright (c) 2012 - 2020 Jolla Ltd.
 * Copyright (c) 2019 - 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import Sailfish.Telephony 1.0
import org.nemomobile.commhistory 1.0
import org.nemomobile.contacts 1.0
import Nemo.DBus 2.0
import "../common"

ContactBrowser {
    id: root

    property int headerHeight

    property int _contactActionType

    function reset() {
        root.resetScrollPosition()
    }

    function openNewContactEditor() {
        ContactsUtil.editContact(ContactCreator.createContact({}), people, pageStack)
    }

    function _clearContextMenu(contextMenu) {
        // Hide existing menu items.
        var content = contextMenu._contentColumn
        for (var i = 0; i < content.children.length; i++) {
            content.children[i].visible = false
        }

        // Clear the menu highlight.
        contextMenu._setHighlightedItem(null)
    }

    function _propertySelected(contact, propertyData, contextMenu, propertyPicker) {
        if (!propertyData.property) {
            console.log("No phone numbers found for contact:", contact.displayLabel)
            return
        }

        if (_contactActionType === Telephony.Call
                && Telephony.promptForVoiceSim
                && propertyData.propertyType === "phoneNumber") {

            propertyPicker.closeOnSelection = false
            var menuProperties = {
                "propertyData": propertyData,
                "propertyPicker": propertyPicker
            }
            if (contextMenu) {
                // Show the SIM picker within the active context menu.
                menuProperties["menu"] = contextMenu
                _clearContextMenu(contextMenu)
                simPickerComponent.createObject(contextMenu, menuProperties)
            } else {
                // Open a context menu with the SIM picker.
                root.openContextMenu(contact.id, simPickerContextMenuComponent, menuProperties)
            }
        } else {
            _triggerContactAction(propertyData, "")
        }
    }

    function _triggerContactAction(propertyData, modemPath) {
        if (_contactActionType === Telephony.Message) {
            messaging.startSMS(propertyData.property.number)
        } else {
            telephony.dialNumberOrService(propertyData.property.number, modemPath)
        }
    }

    onContactClicked: {
        pageStack.animatorPush('Sailfish.Contacts.ContactCardPage',
                               // reload contact from model in case it has changed
                               { 'contact': people.personById(contact.id) })
    }

    onContactPressAndHold: {
        root.openContextMenu(contact.id, contextMenuComponent, { "contact": contact })
    }

    // Select the contact's specific phone number to dial
    recentContactsCategoryMask: CommHistory.ShortMessagingCategory | CommHistory.MultimediaMessagingCategory | CommHistory.InstantMessagingCategory
    symbolScroller {
        topMargin: 0
    }
    topMargin: headerHeight
    canSelect: false
    searchActive: true

    placeholder: Column {
        width: parent ? parent.width : Screen.width
        spacing: 2 * Theme.paddingLarge

        InfoLabel {
            //: View placeholder shown when the people tab is empty
            //% "You don't have any contacts yet"
            text: qsTrId("voicecall-la-no_contacts_yet")
        }

        ButtonLayout {
            Button {
                //% "Create a new contact"
                text: qsTrId("voicecall-bt-create_new_contact")
                onClicked: openNewContactEditor()
            }
            Button {
                ButtonLayout.newLine: true
                //% "Import contacts"
                text: qsTrId("voicecall-bt-import_contacts")
                onClicked: contactsDbusIface.call('importWizard', [])

                DBusInterface {
                    id: contactsDbusIface
                    service: "com.jolla.contacts.ui"
                    path: "/com/jolla/contacts/ui"
                    iface: "com.jolla.contacts.ui"
                }
            }
        }
    }

    PullDownMenu {

        MenuItem {
            //: Show contact search view
            //% "Search"
            text: qsTrId("voicecall-me-search")
            visible: root.allContactsModel.count > 0
            onClicked: root.forceSearchFocus()
        }

        MenuItem {
            //: Initiates adding a new contact
            //% "Add contact"
            text: qsTrId("voicecall-me-add_contact")
            onClicked: openNewContactEditor()
        }
    }

    Component {
        id: contextMenuComponent

        ContextMenu {
            id: contextMenu

            property var contact
            readonly property bool _hasPhoneNumber: contact.phoneDetails.length > 0

            // The phone number property selection and SIM selection will also be embedded into
            // this menu, so don't auto-close it when an option is selected.
            closeOnActivation: false

            hasContent: (_hasPhoneNumber && (telephony.callingPermitted || telephony.messagingPermitted)) || deleteMenu.visible

            function _choosePhoneNumber(actionType) {
                _clearContextMenu(contextMenu)
                root._contactActionType = actionType
                root.selectContactProperty(contact.id, PeopleModel.PhoneNumberRequired, root._propertySelected)
            }

            MenuItem {
                //% "Call"
                text: qsTrId("voicecall-me-call")
                visible: contextMenu._hasPhoneNumber && telephony.callingPermitted
                onClicked: _choosePhoneNumber(Telephony.Call)
            }

            MenuItem {
                //% "Send message"
                text: qsTrId("voicecall-me-send_message")
                visible: contextMenu._hasPhoneNumber && telephony.messagingPermitted
                onClicked: _choosePhoneNumber(Telephony.Message)
            }

            MenuItem {
                id: deleteMenu
                //% "Delete contact"
                text: qsTrId("voicecall-me-delete_contact")
                visible: contextMenu.parent && contextMenu.parent.canDeleteContact
                onClicked: {
                    contextMenu.close()
                    contextMenu.parent.deleteContact()
                }
            }
        }
    }

    Component {
        id: simPickerComponent

        SimPickerMenuItem {
            id: simPicker

            property var propertyData
            property var propertyPicker

            active: true

            onTriggerAction: {
                root._triggerContactAction(propertyData, modemPath)
                propertyPicker.closeMenu()
                simPicker.destroy()
            }
        }
    }

    Component {
        id: simPickerContextMenuComponent

        ContextMenu {
            id: contextMenu

            // Need at least one item to make the menu visible.
            MenuItem {}

            SimPickerMenuItem {
                id: simPicker

                property var propertyData
                property var propertyPicker

                active: true
                menu: contextMenu

                onTriggerAction: {
                    root._triggerContactAction(propertyData, modemPath)
                    propertyPicker.closeMenu()
                    simPicker.destroy()
                }
            }
        }
    }
}
