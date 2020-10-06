/*
 * Copyright (c) 2013 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import QtQuick.Window 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0

SystemDialog {
    id: root

    property var promptConfig: ({})
    property bool windowVisible: visibility != Window.Hidden
                                 && visibility != Window.Minimized

    signal done(var window, bool unregister)

    function init(promptConfig) {
        root.promptConfig = promptConfig
        raise()
        show()
    }

    contentHeight: container.height
    onDismissed: root.done(root, false)

    Rectangle {
        id: container

        width: root.width
        height: content.height
        color: Theme.overlayBackgroundColor

        Column {
            id: content
            width: parent.width

            SystemDialogHeader {
                id: header

                title: root.promptConfig.title || ""
                description: root.promptConfig.subtitle || ""
            }

            Label {
                id: bodyLabel

                anchors.horizontalCenter: parent.horizontalCenter
                width: root.width - 2*Theme.horizontalPageMargin
                height: implicitHeight + Theme.paddingLarge
                font.pixelSize: Theme.fontSizeSmall
                horizontalAlignment: Text.AlignHCenter
                color: Theme.highlightColor
                wrapMode: Text.Wrap
                text: root.promptConfig.body || ""
            }

            SystemDialogTextButton {
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.width

                //% "Close"
                text: qsTrId("lipstick-jolla-home-bt-close")

                onClicked: {
                    root.done(root, false)
                }
            }
        }
    }
}
