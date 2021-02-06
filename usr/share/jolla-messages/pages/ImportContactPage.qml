/*
 * Copyright (c) 2013 - 2019 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

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
                    var body
                    if (MessageUtils.peopleModel.savePerson(contact)) {
                        //% "Saved contact"
                        body = qsTrId("messages-la-saved_contact")
                        pageStack.pop()
                    } else {
                        //% "Error saving contact"
                        body = qsTrId("messages-la-error_saving_contact")
                    }
                    mainPage.publishNotification(body)
                }
            }

            // Do we want to allow sharing from here?
        }
    }
}
