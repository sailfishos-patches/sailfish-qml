/****************************************************************************
**
** Copyright (C) 2016 Jolla Ltd.
** Contact: Bea Lam <bea.lam@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import QtQuick.Window 2.0
import Sailfish.Silica 1.0
import Sailfish.Bluetooth 1.0
import Sailfish.Lipstick 1.0

SystemDialog {
    id: root

    property string deviceAddress
    property string deviceName
    property string fileName

    property bool windowVisible: visibility != Window.Hidden
                                 && visibility != Window.Minimized

    signal done(bool acceptFile)

    function init(deviceAddress, deviceName, fileName) {
        root.deviceAddress = deviceAddress
        root.deviceName = deviceName
        root.fileName = fileName

        raise()
        show()
    }

    autoDismiss: true
    contentHeight: content.height

    onDismissed: {
        root.done(false)
    }

    Rectangle {
        width: parent.width
        height: content.height
        color: Theme.overlayBackgroundColor

        Column {
            id: content
            width: parent.width

            SystemDialogHeader {
                id: header

                //: Another Bluetooth device has requested a connection to this device
                //% "Bluetooth file transfer"
                title: qsTrId("lipstick-jolla-home-he-bluetooth_file_transfer")

                //: Ask the user to allow/deny an incoming file transfer from another Bluetooth device. %1 = the other device's name
                //% "Receive the following file from %1?"
                description: qsTrId("lipstick-jolla-home-la-obex_receive_file").arg(root.deviceName)
            }

            Label {
                width: parent.width
                height: implicitHeight + Theme.paddingLarge
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeLarge
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                text: root.fileName
            }

            Item {
                width: parent.width
                height: Math.max(cancelButton.implicitHeight, confirmButton.implicitHeight)

                SystemDialogTextButton {
                    id: cancelButton
                    width: parent.width / 2

                    //: Disallow the file transfer from the other Bluetooth device
                    //% "No"
                    text: qsTrId("lipstick-jolla-home-la-file_transfer_deny")

                    onClicked: {
                        root.done(false)
                    }
                }

                SystemDialogTextButton {
                    id: confirmButton
                    anchors.right: parent.right
                    width: parent.width / 2

                    //: Allow the file transfer from the other Bluetooth device
                    //% "Yes"
                    text: qsTrId("lipstick-jolla-home-la-file_transfer_allow")

                    onClicked: {
                        root.done(true)
                    }
                }
            }
        }
    }
}
