import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0 as Contacts
import org.nemomobile.contacts 1.0

/*!
  \inqmlmodule Sailfish.Contacts
*/
ContactItem {
    id: contactItem

    // Use getPerson() to access the person object so one isn't instantiated unnecessarily
    property int contactId
    property bool canDeleteContact: true
    property var peopleModel: ListView.view.model

    property var selectionModel
    readonly property int selectionModelIndex: selectionModel !== null ? (selectionModel.count > 0, selectionModel.findContactId(contactId)) : -1 // count to retrigger on change.
    property var propertyPicker

    property int symbolScrollBarWidth
    property bool symbolScrollBarVisible

    signal contactClicked(var contact)
    signal contactPressAndHold(var contact)

    function deleteContact() {
        if (contactId && peopleModel && getPerson()) {
            // Retrieve the person to delete; it will be no longer accessible if the
            // remorse function is triggered by delegate destruction
            // Similarly, cache a reference to the contact model cache.
            var contactModelCache = Contacts.ContactModelCache
            var person = getPerson()
            var item = remorseDelete(function () {
                contactModelCache.deleteContact(person)
            })
            item.rightMargin = !symbolScrollBarVisible ? Theme.horizontalPageMargin
                                                       : Theme.paddingMedium + symbolScrollBarWidth
        }
    }

    function personObject() {
        return getPerson()
    }

    hidden: Contacts.ContactModelCache._deletingContactId === contactId
    highlighted: down || menuOpen || selectionModelIndex >= 0
    openMenuOnPressAndHold: false

    onClicked: {
        contactClicked(getPerson())
    }

    onPressAndHold: {
        contactPressAndHold(getPerson())
    }
}
