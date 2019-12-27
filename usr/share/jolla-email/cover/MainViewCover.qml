/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root

    property int unreadMailCount: app.numberOfAccounts === 1 ? app.inboxUnreadCount
                                                             : app.combinedInboxUnreadCount

    anchors.fill: parent

    Behavior on opacity { FadeAnimation { duration: 500 } }
    Label {
        id: unreadCount
        text: unreadMailCount
        x: Theme.paddingLarge
        y: Theme.paddingMedium
        visible: !app.syncInProgress
        font.pixelSize: Theme.fontSizeHuge
    }
    Label {
        id: unreadLabel

        //: Unread label. Code requires exact line break tag "<br/>".
        //% "Unread<br/>email(s)"
        text: qsTrId("jolla-email-la-unread-emails", unreadMailCount).replace("<br/>", "\n")
        font.pixelSize: Theme.fontSizeExtraSmall
        visible: !app.syncInProgress
        maximumLineCount: 2
        wrapMode: Text.Wrap
        fontSizeMode: Text.HorizontalFit
        lineHeight: 0.8
        height: implicitHeight/0.8
        verticalAlignment: Text.AlignVCenter
        anchors {
            right: parent.right
            left: unreadCount.right
            leftMargin: Theme.paddingMedium
            baseline: unreadCount.baseline
            baselineOffset: lineCount > 1 ? -implicitHeight/2 : -(height-implicitHeight)/2
        }
    }
    OpacityRampEffect {
        offset: 0.5
        sourceItem: unreadLabel
        enabled: unreadLabel.implicitWidth > Math.ceil(unreadLabel.width)
    }

    CoverLabel {
        id: statusLabel

        //: Updating label
        //% "Updating..."
        text: app.syncInProgress ? qsTrId("jolla-email-la-updating") :
                                   app.errorOccurred ? app.lastErrorText : app.lastAccountUpdate
        anchors { top: unreadCount.baseline; topMargin: Theme.paddingLarge }
        height: parent.height - coverActionArea.height - statusLabel.y - Theme.paddingMedium
        fontSizeMode: Text.VerticalFit
        font.pixelSize: Theme.fontSizeLarge
        wrapMode: app.syncInProgress ? Text.NoWrap : Text.Wrap
        width: parent.width - Theme.paddingLarge
        color: Theme.highlightColor
        elide: Text.ElideNone
        maximumLineCount: 3
        Timer {
            property bool keepVisible

            repeat: true
            interval: 500
            running: app.syncInProgress && emailCover.status === Cover.Active
            onRunningChanged: if (!running) root.opacity = 1.0
            onTriggered: {
                if (keepVisible) {
                    keepVisible = false
                } else {
                    keepVisible = root.opacity < Theme.opacityLow
                    root.opacity = (root.opacity > Theme.opacityLow ? 0.0 : 1.0)
                }
            }
        }
    }
    OpacityRampEffect {
        offset: 0.5
        sourceItem: statusLabel
        enabled: statusLabel.implicitWidth > statusLabel.width - Theme.paddingLarge
    }
    CoverActionList {
        enabled: app.numberOfAccounts > 0
        CoverAction {
            iconSource: "image://theme/icon-cover-sync"
            onTriggered: {
                emailAgent.accountsSync(true)
            }
        }
    }
}
