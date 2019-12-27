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
import org.kde.bluezqt 1.0 as BluezQt

SystemDialog {
    id: root

    property QtObject bluetoothManager: BluezQt.Manager
    property string deviceAddress
    property string deviceName
    property string serviceUuid
    property int requestId

    property bool windowVisible: visibility != Window.Hidden
                                 && visibility != Window.Minimized

    property QtObject device

    signal done(bool authorized)

    function init(deviceAddress, deviceName, serviceUuid, requestId) {
        root.deviceAddress = deviceAddress
        root.deviceName = deviceName
        root.serviceUuid = serviceUuid
        root.requestId = requestId

        if (bluetoothManager.initialized) {
            root.device = bluetoothManager.deviceForAddress(deviceAddress)
        } else {
            bluetoothManager.initFinished.connect(function() {
                root.device = bluetoothManager.deviceForAddress(deviceAddress)
            })
        }

        raise()
        show()
    }

    autoDismiss: true
    contentHeight: content.height

    onDismissed: {
        done(false)
    }

    Rectangle {
        width: root.width
        height: content.height
        color: Theme.overlayBackgroundColor

        Column {
            id: content
            width: parent.width

            SystemDialogHeader {
                id: header

                //: Another Bluetooth device has requested a connection to this device
                //% "Connection request"
                title: qsTrId("lipstick-jolla-home-he-connection_request")

                description: {
                    var serviceName = BluetoothProfiles.profileNameFromUuid(serviceUuid)
                    return serviceName.length == 0
                        //: Confirm whether another Bluetooth device should be allowed to connect to some Bluetooth service on this Jolla device (%1 = name of other device)
                        //% "Allow connection from %1?"
                      ? qsTrId("lipstick-jolla-home-la-bluetooth_authorize_service_connection_to_unknown_service").arg(root.deviceName)
                        //: Confirm whether another Bluetooth device should be allowed to connect to the specified Bluetooth service on this Jolla device (%1 = name of other device, %2 = name of service)
                        //% "Allow %1 to connect to the %2 service?"
                      : qsTrId("lipstick-jolla-home-la-bluetooth_authorize_service_connection_to_named_service").arg(root.deviceName).arg(serviceName)
                }
            }

            TrustBluetoothDeviceSwitch {
                checked: root.device && root.device.trusted
                enabled: root.device != null
                onClicked: {
                    if (root.device) {
                        root.device.trusted = checked
                    } else {
                        console.log("Cannot set trusted state, cannot find device", root.deviceAddress)
                    }
                }
            }

            Item {
                width: parent.width
                height: Math.max(cancelButton.implicitHeight, confirmButton.implicitHeight)

                SystemDialogTextButton {
                    id: cancelButton
                    width: root.width / 2

                    //: Disallow the other Bluetooth device from connecting to this one
                    //% "No"
                    text: qsTrId("lipstick-jolla-home-la-service_connect_deny")

                    onClicked: {
                        root.done(false)
                        root.lower()
                    }
                }

                SystemDialogTextButton {
                    id: confirmButton
                    anchors.right: parent.right
                    width: root.width / 2

                    //: Allow the other Bluetooth device to connect to this one
                    //% "Yes"
                    text: qsTrId("lipstick-jolla-home-la-service_connect_allow")

                    onClicked: {
                        root.done(true)
                        root.lower()
                    }
                }
            }
        }
    }
}
