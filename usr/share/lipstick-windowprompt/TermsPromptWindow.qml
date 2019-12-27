/****************************************************************************
**
** Copyright (C) 2017 Jolla Ltd.
** Contact: Bea Lam <bea.lam@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import QtQuick.Window 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0

SystemDialog {
    id: root

    property var promptConfig: ({})

    property bool windowVisible: visibility != Window.Hidden
                                 && visibility != Window.Minimized

    readonly property real _maxWindowHeight: Screen.height * 0.75

    signal done(var window, bool unregister)

    function init(promptConfig) {
        root.promptConfig = promptConfig
        raise()
        show()
    }

    autoDismiss: false
    contentHeight: container.height

    Rectangle {
        id: container

        width: root.width
        height: Math.min(content.height, _maxWindowHeight)
        color: Theme.overlayBackgroundColor

        Flickable {
            anchors.fill: parent
            contentHeight: content.height

            Column {
                id: content
                width: parent.width

                SystemDialogHeader {
                    id: header
                    title: root.promptConfig.title || ""
                    description: root.promptConfig.summary || ""
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
                    id: confirmButton
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: root.width / 2
                    text: root.promptConfig.triggerAccept || ""

                    onClicked: {
                        root.done(root, true)
                    }
                }
            }
        }
    }
}
