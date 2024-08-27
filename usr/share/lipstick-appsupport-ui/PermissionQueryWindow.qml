/*
 * Copyright (c) 2024 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import QtQuick.Window 2.0 as QtQuick
import Sailfish.Silica 1.0
import Sailfish.Bluetooth 1.0
import Sailfish.Lipstick 1.0

SystemDialog {
    id: root

    readonly property int buttonAllow: 1
    readonly property int buttonAllowAlways: 2
    readonly property int buttonAllowForeground: 4
    readonly property int buttonDeny: 8
    readonly property int buttonDenyAndDontAsk: 16
    readonly property int buttonAllowOnce: 32
    readonly property int buttonNoUpgrade: 64
    readonly property int buttonNoUpgradeAndDontAsk: 128
    readonly property int buttonNoUpgradeOnce: 256
    readonly property int buttonNoUpgradeOnceAndDontAsk: 512
    readonly property int buttonLinkToSettings: 1024

    readonly property int replyLinkedToSettings: -2
    readonly property int replyCanceled: -1
    readonly property int replyGrantedAlways: 0
    readonly property int replyGrantedForegroundOnly: 1
    readonly property int replyDenied: 2
    readonly property int replyDeniedDoNotAsk: 3
    readonly property int replyGrantedOnce: 4

    property string uuid
    property string message
    property string detailedMessage
    property int buttonVisibility
    property string groupName
    property var buttonTexts

    property bool windowVisible: visibility != QtQuick.Window.Hidden
                                 && visibility != QtQuick.Window.Minimized

    signal done(string uuid, int result)

    function init(uuid, buttonVisibility, groupName, message, detailedMessage, buttonTexts) {
        root.uuid = uuid
        root.buttonVisibility = buttonVisibility
        root.message = message
        root.detailedMessage = detailedMessage
        root.groupName = groupName
        root.buttonTexts = buttonTexts

        raise()
        show()
    }

    autoDismiss: true
    contentHeight: content.height

    onDismissed: {
        root.done(uuid, replyCanceled)
    }

    Column {
        id: content
        width: parent.width
        topPadding: Math.max(Theme.paddingLarge * 3,
                             (root.orientation == Qt.PortraitOrientation && Screen.topCutout.height > 0)
                             ? Screen.topCutout.height + Theme.paddingSmall : 0)
        bottomPadding: Theme.paddingLarge

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Image.AlignHCenter
            verticalAlignment: Image.AlignVCenter
            fillMode: Image.Pad

            source: {
                if (root.groupName === "android.permission-group.STORAGE")
                    return "image://theme/icon-m-storage"
                else if (root.groupName === "android.permission-group.CAMERA")
                    return "image://theme/icon-m-camera"
                else if (root.groupName === "android.permission-group.MICROPHONE")
                    return "image://theme/icon-m-mic"
                else if (root.groupName === "android.permission-group.CONTACTS")
                    return "image://theme/icon-m-contact"
                else if (root.groupName === "android.permission-group.CALENDAR")
                    return "image://theme/icon-m-alarm"
                else if (root.groupName === "android.permission-group.LOCATION")
                    return "image://theme/icon-m-location"
                else if (root.groupName === "android.permission-group.PHONE_CALLS")
                    return "image://theme/icon-m-call"
                else if (root.groupName === "android.permission-group.PHONE")
                    return "image://theme/icon-m-call"
                else if (root.groupName === "android.permission-group.SMS")
                    return "image://theme/icon-m-sms"
                else
                    return "image://theme/icon-m-question"
            }
        }

        SystemDialogHeader {
            topPadding: 2 * Theme.paddingLarge
            // These are received in translated state
            title: root.message
            description: root.detailedMessage
        }

        Column {
            width: parent.width

            SystemDialogTextButton {
                width: parent.width
                visible: root.buttonVisibility & buttonAllow
                bottomPadding: topPadding

                text: root.buttonTexts[0]

                onClicked: {
                    root.done(root.uuid, replyGrantedAlways)
                }
            }

            SystemDialogTextButton {
                width: parent.width
                visible: root.buttonVisibility & buttonAllowAlways
                bottomPadding: topPadding

                text: root.buttonTexts[1]

                onClicked: {
                    root.done(root.uuid, replyGrantedAlways)
                }
            }

            SystemDialogTextButton {
                width: parent.width
                visible: root.buttonVisibility & buttonAllowForeground
                bottomPadding: topPadding

                text: root.buttonTexts[2]

                onClicked: {
                    root.done(root.uuid, replyGrantedForegroundOnly)
                }
            }

            SystemDialogTextButton {
                width: parent.width
                visible: root.buttonVisibility & buttonAllowOnce
                bottomPadding: topPadding

                text: root.buttonTexts[5]

                onClicked: {
                    root.done(root.uuid, replyGrantedOnce)
                }
            }

            SystemDialogTextButton {
                width: parent.width
                visible: root.buttonVisibility & buttonDeny
                bottomPadding: topPadding

                text: root.buttonTexts[3]

                onClicked: {
                    root.done(root.uuid, replyDenied)
                }
            }

            SystemDialogTextButton {
                width: parent.width
                visible: root.buttonVisibility & buttonDenyAndDontAsk
                bottomPadding: topPadding

                text: root.buttonTexts[4]

                onClicked: {
                    root.done(root.uuid, replyDeniedDoNotAsk)
                }
            }

            SystemDialogTextButton {
                width: parent.width
                visible: root.buttonVisibility & buttonNoUpgrade
                bottomPadding: topPadding

                text: root.buttonTexts[6]

                onClicked: {
                    root.done(root.uuid, replyDenied)
                }
            }

            SystemDialogTextButton {
                width: parent.width
                visible: root.buttonVisibility & buttonNoUpgradeAndDontAsk
                bottomPadding: topPadding

                text: root.buttonTexts[7]

                onClicked: {
                    root.done(root.uuid, replyDeniedDoNotAsk)
                }
            }

            SystemDialogTextButton {
                width: parent.width
                visible: root.buttonVisibility & buttonNoUpgradeOnce
                bottomPadding: topPadding

                text: root.buttonTexts[8]

                onClicked: {
                    root.done(root.uuid, replyDenied)
                }
            }

            SystemDialogTextButton {
                width: parent.width
                visible: root.buttonVisibility & buttonNoUpgradeOnceAndDontAsk
                bottomPadding: topPadding

                text: root.buttonTexts[9]

                onClicked: {
                    root.done(root.uuid, replyDeniedDoNotAsk)
                }
            }

            SystemDialogTextButton {
                width: parent.width
                visible: root.buttonVisibility & buttonLinkToSettings
                bottomPadding: topPadding

                text: root.buttonTexts[10]

                onClicked: {
                    root.done(root.uuid, replyLinkedToSettings)
                }
            }
        }
    }
}
