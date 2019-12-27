import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Messages 1.0
import org.nemomobile.contacts 1.0
import Sailfish.Contacts 1.0

Page {
    id: root
    property alias contact: contactCard.contact

    ContactCard {
        id: contactCard

        PullDownMenu {
            MenuItem {
                //% "Save"
                text: qsTrId("messages-me-save_contact")
                onClicked: {
                    var previewBody
                    if (MessageUtils.peopleModel.savePerson(contact)) {
                        //% "Saved contact"
                        previewBody = qsTrId("messages-la-saved_contact")
                        pageStack.pop()
                    } else {
                        //% "Error saving contact"
                        previewBody = qsTrId("messages-la-error_saving_contact")
                    }
                    mainPage.publishNotification(previewBody)
                }
            }

            // Do we want to allow sharing from here?
        }
    }
}
