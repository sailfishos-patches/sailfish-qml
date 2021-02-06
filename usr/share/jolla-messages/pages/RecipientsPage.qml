/*
 * Copyright (c) 2013 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Messages 1.0
import Sailfish.Contacts 1.0

Page {
    property var recipients

    ListModel {
        id: recipientModel
    }

    onRecipientsChanged: {
        recipientModel.clear()
        for (var i = 0; i < recipients.length; i++) {
            var person = recipients[i].id === 0 ? recipients[i] : MessageUtils.peopleModel.personById(recipients[i].id)
            recipientModel.append({ "person": person })
        }
    }

    SilicaListView {
        id: list
        anchors.fill: parent

        model: recipientModel

        header: PageHeader {
            //% "Recipients"
            title: qsTrId("messages-he-recipients")
        }

        delegate: ContactItem {
            width: list.width

            firstText: person.primaryName
            secondText: person.secondaryName
            presenceState: person.globalPresenceState

            onClicked: {
                pageStack.animatorPush("Sailfish.Contacts.ContactCardPage", { "contact": person })
            }
        }
    }
}
