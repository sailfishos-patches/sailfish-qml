/*
 * Copyright (c) 2018 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1
import org.nemomobile.configuration 1.0

Dialog {
    id: root

    property alias originalEmailId: originalEmail.messageId

    canAccept: true

    EmailMessage {
        id: originalEmail
    }

    DialogHeader {
        //% "Send receipt"
        acceptText: qsTrId("email-dh-accept_send_read_receipt")
        //% "Ignore"
        cancelText: qsTrId("email-dh-do_not_send_read_receipt")
    }

    Column {
        width: parent.width
        spacing: Theme.paddingLarge
        anchors {
            top: parent.top
            topMargin: Theme.itemSizeLarge // Page header size
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeHuge
            color: Theme.highlightColor
            //% "Read receipt requested"
            text: qsTrId("jolla-email-la-send_read_receipt")
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.highlightColor
            //% "Sender requested a read receipt. Do you want to send a receipt?"
            text: qsTrId("jolla-email-la-send_read_receipt_description")
        }
        TextSwitch {
            id: rememberChoiceSwitch
            //% "Remember my choice"
            text: qsTrId("jolla-email-ts-remember_choice")
            checked: sendReadReceiptsConfig.value
        }
    }

    onAccepted: {
        if (originalEmail.messageId && !originalEmail.sendReadReceipt(
                    //% "Read: "
                    qsTrId("jolla-email-la-read_receipt_email_subject_prefix"),
                    //: %1:original email timestamp; %2:date of an email; %3:receiver email address
                    //% "Your email sent at %1 on %2 to %3 was read."
                    qsTrId("jolla-email-la-read_receipt_email_body")
                    .arg(Qt.formatTime(originalEmail.date))
                    .arg(Qt.formatDate(originalEmail.date))
                    .arg(originalEmail.accountAddress))) {
            //% "Failed to send read receipt"
            app.showSingleLineNotification(qsTrId("jolla-email-la-failed_send_read_receipt"))
        }
        if (rememberChoiceSwitch.checked) {
            sendReadReceiptsConfig.value = 1 // means always send
        }
    }
    onRejected: {
        if (rememberChoiceSwitch.checked) {
            sendReadReceiptsConfig.value = 2 // means always ignore
        }
    }

    ConfigurationValue {
        id: sendReadReceiptsConfig
        key: "/apps/jolla-email/settings/sendReadReceipts"
        defaultValue: 0
    }
}
