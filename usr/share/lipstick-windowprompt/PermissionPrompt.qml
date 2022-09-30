/*
 * Copyright (c) 2020 - 2021 Open Mobile Platform LLC.
 * Copyright (c) 2021 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import QtQuick.Window 2.0 as QtQuick
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0

SystemDialog {
    id: root

    property var promptConfig: ({})
    property bool windowVisible: visibility != QtQuick.Window.Hidden
                                 && visibility != QtQuick.Window.Minimized
    readonly property real reservedHeight: (Screen.sizeCategory < Screen.Large ? 0.2 : 0.4)  * screenHeight

    signal done(var window, bool unregister)

    function init(promptConfig) {
        root.promptConfig = promptConfig
        raise()
        show()
        // Trigger here to reset if another dialog is displayed without destructing the component
        autoDismissTimer.restart()
    }

    function reply(accept) {
        promptConfig["accepted"] = accept
        root.done(root, false)
    }

    contentHeight: flickable.height + autoDismissText.height + buttons.height + Theme.paddingSmall

    onDismissed: root.reply(false)

    SilicaFlickable {
        id: flickable
        readonly property real availableHeight: screenHeight - reservedHeight - buttons.height - autoDismissText.height - Theme.paddingSmall
        property real originalContentHeight: content.height
        property bool menuHasBeenOpened
        contentHeight: content.height
        height: Math.min(originalContentHeight, availableHeight)
        width: parent.width
        clip: contentHeight > availableHeight || contentHeight > originalContentHeight
        onMenuHasBeenOpenedChanged: if (menuHasBeenOpened) originalContentHeight = content.height // break binding

        Column {
            id: content

            topPadding: Theme.paddingLarge
            spacing: Theme.paddingLarge
            width: parent.width

            Image {
                property string icon: root.promptConfig.icon || ""
                source: icon != "" ? ((icon.indexOf("/") == 0 ? "file://" : "image://theme/") + icon)
                                   : ""
                anchors.horizontalCenter: parent.horizontalCenter
                height: Theme.iconSizeLauncher
                width: Theme.iconSizeLauncher
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                height: implicitHeight
                font.pixelSize: Theme.fontSizeLarge
                horizontalAlignment: Text.AlignHCenter
                color: Theme.highlightColor
                wrapMode: Text.Wrap
                //: Shown when starting a sandboxed application for the first time, %1 is application name
                //% "%1 needs following access permission(s)"
                text: qsTrId("lipstick-jolla-home-la-jail_disclaimer", promptConfig.permissions !== undefined ? promptConfig.permissions.length : 0).arg(promptConfig.application)
            }

            Column {
                width: parent.width
                Repeater {
                    model: promptConfig.permissions

                    ListItem {
                        id: permissionItem

                        property bool expanded

                        contentItem.clip: expanded
                        contentHeight: description.implicitHeight + 2*description.y
                        width: parent.width
                        onClicked: {
                            flickable.menuHasBeenOpened = true
                            openMenu()
                        }
                        Behavior on contentHeight { NumberAnimation { duration: 100; easing.type: Easing.InOutQuad } }

                        Label {
                            id: description

                            text: modelData["short"]
                            wrapMode: permissionItem.expanded ? Text.Wrap : Text.NoWrap
                            truncationMode: permissionItem.expanded ? TruncationMode.None
                                                                    : TruncationMode.Fade
                            horizontalAlignment: implicitWidth > width || lineCount > 1 ? Text.AlignLeft
                                                                                        : Text.AlignHCenter

                            x: Theme.horizontalPageMargin
                            y: Theme.paddingSmall/2
                            width: parent.width - 2 * x
                        }

                        menu: Component {
                            ContextMenu {
                                onActiveChanged: if (active) permissionItem.expanded = true
                                onClosed: permissionItem.expanded = false

                                hasContent: longDescription.text !== ""

                                Label {
                                    id: longDescription

                                    text: modelData["long"] || ""
                                    color: Theme.highlightColor
                                    x: Theme.horizontalPageMargin
                                    width: parent.width - 2*x
                                    topPadding: Theme.paddingMedium
                                    bottomPadding: Theme.paddingMedium
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.Wrap
                                }
                            }
                        }
                    }
                }
            }
        }

        VerticalScrollDecorator {}
    }

    Label {
        id: autoDismissText

        readonly property int visibleTime: 30
        property int remainingVisibleTime: visibleTime

        //: Dialog closes automatically after certain time has passed, this is shown just before that
        //% "This dialog will be closed in %1 s"
        text: qsTrId("lipstick-jolla-home-la-text_before_auto_dismiss").arg(remainingVisibleTime)
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.highlightColor
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: buttons.top
        }
        x: Theme.horizontalPageMargin
        width: parent.width - 2 * x
        visible: !hideTimer.running

        Timer {
            interval: 10000
            running: !hideTimer.running && autoDismissText.remainingVisibleTime > 10
            repeat: true
            onTriggered: autoDismissText.remainingVisibleTime -= 10
        }

        Timer {
            id: hideTimer
            interval: autoDismissTimer.interval - autoDismissText.visibleTime * 1000
        }
    }

    Row {
        id: buttons
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
        }
        width: parent.width

        SystemDialogTextButton {
            //% "Cancel"
            text: qsTrId("lipstick-jolla-home-bt-cancel")
            width: parent.width / 2
            onClicked: {
                root.dismiss()
                root.reply(false)
            }
        }

        SystemDialogTextButton {
            //% "Accept"
            text: qsTrId("lipstick-jolla-home-bt-accept")
            width: parent.width / 2
            onClicked: {
                root.dismiss()
                root.reply(true)
            }
        }
    }

    /*
     * D-Bus activation timeout is 120 seconds, make this just a little less
     * to allow the application to start before it times out
     */
    Timer {
        id: autoDismissTimer
        interval: 115000
        onTriggered: {
            root.dismiss()
            root.reply(false)
        }
        onRunningChanged: if (running) hideTimer.start()
    }
}
