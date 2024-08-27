/*
* Copyright (c) 2020 Open Mobile Platform LLC.
*
* License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0 as SailfishContacts
import Nemo.Configuration 1.0

AddressBookComboBox {
    id: root

    property var contact

    function saveDefaultAddressBook() {
        defaultAddressBookConfig.value = contact.addressBook.id
    }

    function _setContactAddressBook() {
        if (!!contact && contact.id === 0 && !!defaultAddressBookConfig.value) {
            // This is a new contact, so set the default address book, if available.
            for (var i = 0; i < addressBookModel.count; ++i) {
                var addressBook = addressBookModel.addressBookAt(i)
                if (addressBook.id === defaultAddressBookConfig.value) {
                    contact.addressBook = addressBook
                    return
                }
            }
        }
    }

    label: !!contact && contact.id > 0
             //: Shows the address book to which the contact has been saved
             //% "Saved to"
           ? qsTrId("components_contacts-la-saved_to")
             //: Select the address book to which the contact will be saved
             //% "Save to"
           : qsTrId("components_contacts-la-save_to")

    currentItem: {
        for (var i = 0; i < addressBookRepeater.count; ++i) {
            if (addressBookModel.addressBookAt(i).id === root.contact.addressBook.id) {
                return addressBookRepeater.itemAt(i)
            }
        }
        return addressBookRepeater.itemAt(0)
    }

    // Always show at full opacity, even when disabled.
    opacity: 1
    icon.highlighted: highlighted || !enabled
    icon.monochromeWeight: SailfishContacts.ContactsUtil.iconMonochromeWeight(icon)
    labelColor: highlighted || !enabled ? Theme.highlightColor : Theme.primaryColor

    onAddressBookClicked: {
        root.contact.addressBook = addressBook
    }

    onContactChanged: _setContactAddressBook()

    Connections {
        target: root.addressBookModel

        onCountChanged: _setContactAddressBook()
    }

    ConfigurationValue {
        id: defaultAddressBookConfig

        key: "/org/nemomobile/contacts/default_address_book"
    }
}
