/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

PullDownMenu {
    id: root

    signal removeRequested

    function _openComposer(action) {
        pageStack.animatorPush(Qt.resolvedUrl("ComposerPage.qml"), { popDestination: previousPage, action: action, originalMessageId: message.messageId })
    }

    MenuItem {
        //% "Delete"
        text: qsTrId("jolla-email-me-delete")
        onClicked: {
            pageStack.pop()
            root.removeRequested()
        }
    }
    MenuItem {
        //: Forward message menu item
        //% "Forward"
        text: qsTrId("jolla-email-me-forward")
        onClicked: _openComposer('forward')
    }
    MenuItem {
        visible: replyAll
        //: Reply to all message recipients menu item
        //% "Reply to All"
        text: qsTrId("jolla-email-me-reply_all")
        onClicked: _openComposer('replyAll')
    }
    MenuItem {
        //: Reply to message sender menu item
        //% "Reply"
        text: qsTrId("jolla-email-me-reply")
        onClicked: _openComposer('reply')
    }
}
