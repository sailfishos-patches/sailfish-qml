import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import org.nemomobile.contacts 1.0

ContactSelectPage {
    id: pickerPage

    signal selectedRecipients(var contacts)

    function clearSelections() {
        contactSelectionModel.removeAllContacts()
    }

    onContactClicked: {
        contactSelectionModel.addContact(contact.id, property, propertyType)
        pickerPage.selectedRecipients(contactSelectionModel)
        pageStack.pop()
    }

    ContactSelectionModel {
        id: contactSelectionModel
    }

    Connections {
        target: allContactsModel
        onRowsAboutToBeRemoved: {
            var selectedRow = -1
            for (var i = first; i <= last; ++i) {
                selectedRow = contactSelectionModel.findContactId(allContactsModel.get(i, PeopleModel.ContactIdRole))
                if (selectedRow >= 0) {
                    contactSelectionModel.removeContactAt(selectedRow)
                }
            }
        }
    }
}
