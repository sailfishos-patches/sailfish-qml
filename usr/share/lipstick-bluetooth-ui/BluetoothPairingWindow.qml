/****************************************************************************
**
** Copyright (C) 2016 Jolla Ltd.
** Contact: Bea Lam <bea.lam@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import QtQuick.Window 2.0
import Nemo.DBus 2.0
import Sailfish.Silica 1.0
import Sailfish.Bluetooth 1.0
import org.kde.bluezqt 1.0 as BluezQt
import Sailfish.Lipstick 1.0

SystemDialog {
    id: root

    property QtObject bluetoothManager: BluezQt.Manager
    property string deviceAddress
    property string deviceName
    property QtObject device

    property int action
    readonly property string enteredPasskey: passkeyInputField.text

    property bool windowVisible: visibility != Window.Hidden
                                 && visibility != Window.Minimized

    property string _passkey
    property string _errorText
    property bool _initiatedPairing
    property bool _tryingSimplePin
    property bool _triedSimplePin

    signal pairingAccepted()
    signal pairingRejected()
    signal done()

    onDeviceAddressChanged: {
        if (deviceAddress.length) {
            if (bluetoothManager.initialized) {
                root.device = bluetoothManager.deviceForAddress(deviceAddress)
            } else {
                bluetoothManager.initFinished.connect(function() {
                    root.device = bluetoothManager.deviceForAddress(deviceAddress)
                })
            }
        }
    }

    function initiatedPairingRequest(deviceAddress, deviceName) {
        root.action = -1
        root.deviceAddress = deviceAddress
        root.deviceName = deviceName
        root._passkey = ""
        root._initiatedPairing = true
        content.state = "waitingToInitiatePairing"

        root.raise()
        root.show()
    }

    function agentAction(deviceAddress, deviceName, action, passkey) {
        root.deviceAddress = deviceAddress
        root.deviceName = deviceName
        root.action = action
        root._passkey = passkey

        if (action == BluetoothSystemAgent.EnterPin && root._initiatedPairing && !root._tryingSimplePin) {
            // if initiating a PIN-code pairing, try once with a 0000 PIN
            console.log("Bluetooth pairing: try pairing with preset PIN")
            content.state = "waitForPairingConfirmation"
            passkeyInputField.text = "0000"
            root._tryingSimplePin = true
            root.pairingAccepted()
        } else {
            content.state = "userInput"
        }

        root.raise()
        root.show()
    }

    function finishPairing(errorText) {
        if (!windowVisible) {
            return false
        }
        if (delayedPairingAttempt.running) {
            return true
        }
        if (errorText.length && root._tryingSimplePin && !root._triedSimplePin && root._initiatedPairing) {
            // simple PIN failed: try to pair again after brief delay (for connection to tear down)
            console.log("Bluetooth pairing: preset PIN failed")
            delayedPairingAttempt.start()
            root._triedSimplePin = true
            return true
        }
        if (errorText.length) {
            _errorText = errorText
        }
        // Let's reset these
        root._tryingSimplePin = false
        root._initiatedPairing = false
        root._triedSimplePin = false

        content.state = errorText.length ? "error" : "success"
        return true
    }

    function _done() {
        root.lower()
        root.hide()
        root.done()
    }

    autoDismiss: false
    contentHeight: content.height

    Timer {
        id: delayedPairingAttempt
        interval: 5000
        onTriggered: lipstickBluetoothService.call("pairWithDevice", [root.deviceAddress])
    }

    DBusInterface {
        id: lipstickBluetoothService
        service: "com.jolla.lipstick"
        path: "/bluetooth"
        iface: "com.jolla.lipstick"
    }

    Connections {
        target: root.device
        onPairedChanged: {
            if (content.state == "waitForPairingConfirmation"
                    && device.paired) {
                content.state = "success"
            }
        }
    }

    Rectangle {
        width: root.width
        height: content.height
        color: Theme.overlayBackgroundColor

        Column {
            id: content

            width: parent.width
            spacing: Theme.paddingMedium

            states: [
                State {
                    name: "waitingToInitiatePairing"
                    PropertyChanges {
                        target: busyIndicator
                        running: true
                    }
                    PropertyChanges {
                        target: cancelButton
                        visible: true
                    }
                },
                State {
                    name: "userInput"
                    PropertyChanges {
                        target: header
                        description: {
                            switch (root.action) {
                            case BluetoothSystemAgent.Compare:
                            case BluetoothSystemAgent.DisplayPasskey:
                            case BluetoothSystemAgent.DisplayPin:
                                //: A Bluetooth pairing operation has started and the user must confirm the same number is shown on both Bluetooth devices
                                //% "Confirm the same number on both devices"
                                return qsTrId("lipstick-jolla-home-la-confirm_same_number_shown_on_both_devices")
                            case BluetoothSystemAgent.EnterPasskey:
                            case BluetoothSystemAgent.EnterPin:
                                //: A Bluetooth pairing operation has started and the user must confirm the same number is shown on both Bluetooth devices
                                //% "Enter the PIN below"
                                return qsTrId("lipstick-jolla-home-la-enter_pairing_code")
                            default:    // Authorize action, for just-works pairing
                                //: Shown when a Bluetooth pairing operation is triggered
                                //% "Do you want to pair with this device?"
                                return qsTrId("lipstick-jolla-home-la-authorize_pairing")
                            }
                        }
                    }
                    PropertyChanges {
                        target: passkeyInputField
                        visible: root.action == BluetoothSystemAgent.EnterPasskey || root.action == BluetoothSystemAgent.EnterPin
                        text: ""
                    }
                    PropertyChanges {
                        target: passkeyLabel
                        visible: root.action == BluetoothSystemAgent.Compare
                                 || root.action == BluetoothSystemAgent.DisplayPasskey
                                 || root.action == BluetoothSystemAgent.DisplayPin
                    }
                    PropertyChanges {
                        target: confirmButton

                        //: Button to trigger Bluetooth pairing with the displayed device
                        //% "Pair"
                        text: qsTrId("lipstick-jolla-home-bt-pair")

                        // 'display' actions don't require accept/reject
                        visible: root.action != BluetoothSystemAgent.DisplayPasskey && root.action != BluetoothSystemAgent.DisplayPin
                    }
                    PropertyChanges {
                        target: cancelButton
                        visible: true
                    }
                    PropertyChanges {
                        target: root
                        autoDismiss: true
                        onDismissed: {
                            root.pairingRejected()
                        }
                    }
                },
                State {
                    name: "waitForPairingConfirmation"
                    PropertyChanges {
                        target: busyIndicator
                        running: true
                    }
                    PropertyChanges {
                        target: header

                        //: Waiting for the other Bluetooth device to respond
                        //% "Waiting for other device"
                        description: qsTrId("lipstick-jolla-home-la-waiting_for_other_device")
                    }
                },
                State {
                    name: "done"
                    PropertyChanges {
                        target: root
                        autoDismiss: true
                    }
                    PropertyChanges {
                        target: confirmButton

                        //: Close the pairing window
                        //% "Close"
                        text: qsTrId("lipstick-jolla-home-la-close")
                    }
                },
                State {
                    name: "success"
                    extend: "done"
                    PropertyChanges {
                        target: header

                        //: The Bluetooth pairing operation was successful
                        //% "Pairing created"
                        title: qsTrId("lipstick-jolla-home-he-pairing_created")

                        //: Successfully paired with another Bluetooth device. %1 = name of the other device
                        //% "Now paired with %1"
                        description: qsTrId("lipstick-jolla-home-la-now_paired_with").arg(root.deviceName)
                    }
                    PropertyChanges {
                        target: autoConnectSwitch
                        visible: true
                    }
                    StateChangeScript {
                        // trusted=true by default
                        script: autoConnectSwitch.checked = true
                    }
                },
                State {
                    name: "error"
                    extend: "done"
                    PropertyChanges {
                        target: header

                        //: The Bluetooth pairing operation failed
                        //% "Pairing error"
                        title: qsTrId("lipstick-jolla-home-he-pairing_error")
                        description: root._errorText
                                     ? root._errorText
                                       //: Failed to pair with another Bluetooth device. %1 = name of the other device
                                       //% "Unable to pair with %1"
                                     : qsTrId("lipstick-jolla-home-la-bluetooth_pairing_failure").arg(root.deviceName)
                    }
                }
            ]

            SystemDialogHeader {
                id: header

                //: Currently attempting to pair with another Bluetooth device. %1 = name of the other device
                //% "Pair with %1"
                title: qsTrId("lipstick-jolla-home-he-pair_with").arg(root.deviceName)
            }

            BusyIndicator {
                id: busyIndicator
                size: BusyIndicatorSize.Large
                anchors.horizontalCenter: parent.horizontalCenter
                visible: running
            }

            Label {
                id: passkeyLabel
                width: parent.width
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeExtraLarge
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                text: root._passkey
                visible: false
            }

            TextField {
                id: passkeyInputField
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - (Theme.paddingLarge * 4)

                //% "PIN code"
                label: qsTrId("lipstick-jolla-home-la-pin_code")

                //% "Enter PIN"
                placeholderText: qsTrId("lipstick-jolla-home-ph-enter_pin")

                visible: false
                focus: visible

                inputMethodHints: root.action == BluetoothSystemAgent.EnterPasskey
                        ? Qt.ImhFormattedNumbersOnly
                        : (Qt.ImhNoPredictiveText | Qt.ImhPreferNumbers | Qt.ImhNoAutoUppercase)

                EnterKey.enabled: text || inputMethodComposing
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: root.focus = true
            }

            TrustBluetoothDeviceSwitch {
                id: autoConnectSwitch
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - (Theme.paddingLarge * 2)
                visible: false
                onCheckedChanged: {
                    var device = bluetoothManager.deviceForAddress(root.deviceAddress)
                    if (device) {
                        device.trusted = checked
                    } else {
                        console.log("Cannot set trusted state, cannot find device", root.deviceAddress)
                    }
                }
            }

            Item {
                width: parent.width
                height: Theme.paddingMedium + Math.max(cancelButton.implicitHeight, confirmButton.implicitHeight)

                SystemDialogTextButton {
                    id: cancelButton
                    x: confirmButton.visible ? 0 : (parent.width/2) - (width/2)
                    y: parent.height - height
                    width: confirmButton.visible ? root.width / 2 : root.width

                    //: Cancel Bluetooth pairing operation
                    //% "Cancel"
                    text: qsTrId("lipstick-jolla-home-la-cancel")
                    visible: false

                    onClicked: {
                        root.pairingRejected()
                        root._done()
                    }
                }

                SystemDialogTextButton {
                    id: confirmButton
                    x: cancelButton.visible ? parent.width - width : (parent.width/2) - (width/2)
                    y: parent.height - height
                    width: cancelButton.visible ? root.width / 2 : root.width
                    visible: text.length > 0

                    onClicked: {
                        if (content.state == "userInput") {
                            root.pairingAccepted()
                            content.state = "waitForPairingConfirmation"
                        } else if (content.state == "success"
                                   || content.state == "error") {
                            root._done()
                        }
                    }
                }
            }
        }
    }
}
