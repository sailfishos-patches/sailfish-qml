/*
 * Copyright (c) 2012 - 2020 Jolla Ltd.
 * Copyright (c) 2019 - 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Row {
    id: silencedCallButtons

    signal sendMessageClicked()
    signal reminderClicked()
    signal endCallClicked()

    x: Theme.horizontalPageMargin
    width: parent.width - 2 * x

    IconTextButton {
        //: Send quick message as a response to a silenced call (should be short enough to fit)
        //% "Message"
        text: qsTrId("voicecall-bt-message")
        icon.source: "image://theme/icon-m-message"
        visible: telephony.messagingPermitted
        width: parent.width / 3

        onClicked: silencedCallButtons.sendMessageClicked()
    }

    IconTextButton {
        id: endCallButton
        //: Decline call after it has been silenced (should be short enough to fit)
        //% "Decline"
        text: qsTrId("voicecall-bt-decline")
        icon {
            source: "image://theme/icon-l-dialer"
            rotation: 90
            color: callingView.rejectHighlightColor
        }
        width: parent.width / 3

        onClicked: silencedCallButtons.endCallClicked()
    }

    IconTextButton {
        //: Create a reminder to return a dismissed call (should be short enough to fit)
        //% "Remind me"
        text: qsTrId("voicecall-bt-create_reminder")
        icon.source: "image://theme/icon-m-alarm"
        description: callerItem.reminder.exists
                     ? Format.formatDate(callerItem.reminder.when, Formatter.TimeValue)
                     : ""
        width: parent.width / 3

        onClicked: silencedCallButtons.reminderClicked()
    }
}
