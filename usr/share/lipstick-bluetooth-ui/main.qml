/****************************************************************************
**
** Copyright (C) 2016 - 2020 Jolla Ltd.
** Copyright (C) 2020 Open Mobile Platform LLC.
**
****************************************************************************/

import QtQuick 2.0
import QtQuick.Window 2.0
import Sailfish.Silica 1.0
import Sailfish.Bluetooth 1.0
import Sailfish.Lipstick 1.0
import Nemo.DBus 2.0
import org.nemomobile.notifications 1.0 as Nemo
import org.kde.bluezqt 1.0 as BluezQt
import com.jolla.lipstick 0.1

ApplicationWindow {
    id: root

    property BluetoothAuthorizationWindow _serviceAuthWindow
    property QtObject bluetoothManager: BluezQt.Manager
    property bool monitorManagerObjectChanges: true
    property bool windowsVisible: pairing._windowVisible
                                   || (_serviceAuthWindow && _serviceAuthWindow.windowVisible)
    readonly property bool keepAlive: windowsVisible
                                      || bluetoothSession.sessionCount > 0
                                      || bluetoothRemorseShowTimer.running
                                      || (!!_bluetoothOffRemorse && _bluetoothOffRemorse.active)

    property var _bluetoothOffRemorse

    function _agentServiceAuthorizationRequest(deviceAddress, deviceName, uuid, requestId) {
        if (!_serviceAuthWindow) {
            var comp = Qt.createComponent(Qt.resolvedUrl("BluetoothAuthorizationWindow.qml"))
            if (comp.status == Component.Error) {
                console.log("BluetoothAuthorizationWindow.qml error:", comp.errorString())
                request.reject()
                return
            }
            _serviceAuthWindow = comp.createObject(root)
            _serviceAuthWindow.done.connect(function(authorized) {
                var error = (authorized
                             ? BluezQt.PendingCall.NoError
                             : BluezQt.PendingCall.AuthenticationRejected)
                lipstickService.call("replyToAgentRequest", [_serviceAuthWindow.requestId, error, ""])
                root._finishServiceAuthorization()
            })
        }
        _serviceAuthWindow.init(deviceAddress, deviceName, uuid, requestId)
    }

    function _finishServiceAuthorization() {
        if (_serviceAuthWindow) {
            if (_serviceAuthWindow.windowVisible) {
                _serviceAuthWindow.lower()
            }
            root.monitorManagerObjectChanges = false
            return true
        }
        return false
    }

    allowedOrientations: defaultAllowedOrientations
    _defaultPageOrientations: Orientation.All
    _defaultLabelFormat: Text.PlainText
    cover: undefined

    Timer {
        id: delayedQuit

        // Keep the UI alive briefly to avoid restarting it unnecessarily. For example, a device
        // might send an authorization request soon after a pairing is created.
        interval: 5000
        running: !keepAlive

        onTriggered: {
            console.log("lipstick-bluetooth-ui: exiting...")
            if (!keepAlive) {
                Qt.quit()
            }
        }
    }

    Component {
        id: remorseComponent

        SystemDialog {
            function execute() {
                //% "Turning Bluetooth off"
                remorse.execute(qsTrId("lipstick-jolla-home-la-bluetoothoff"));
            }

            function cancel() {
                remorse.cancel()
            }

            contentHeight: remorse.height
            visible: true

            onDismissed: remorse.trigger()

            RemorsePopup {
                id: remorse

                onCanceled: {
                    dismiss()
                }
                onTriggered: {
                    bluetoothSession.remorseTriggered()
                    dismiss()
                }
            }
        }
    }

    BluetoothSession {
        id: bluetoothSession

        onTurningBluetoothOn: bluetoothEnabledNotification.publish()

        onSessionCountChanged: {
            if (sessionCount > 0) {
                if (!!root._bluetoothOffRemorse) {
                    root._bluetoothOffRemorse.cancel()
                }
                bluetoothRemorseShowTimer.stop()
            } else if (sessionCount === 0 && autoPowerOff) {
                bluetoothRemorseShowTimer.start()
            }
        }
    }

    Connections {
        target: BluezQt.Manager.usableAdapter

        onPoweredChanged: {
            if (!BluezQt.Manager.usableAdapter.powered) {
                if (!!root._bluetoothOffRemorse) {
                    root._bluetoothOffRemorse.cancel()
                }
                bluetoothRemorseShowTimer.stop()
            }
        }
    }

    Timer {
        id: bluetoothRemorseShowTimer

        // Wait 10 seconds before turning off Bluetooth in case it is used again
        interval: 10 * 1000

        onTriggered: {
            if (bluetoothSession.sessionCount > 0 || !bluetoothSession.autoPowerOff) {
                return
            }
            if (!!root._bluetoothOffRemorse) {
                root._bluetoothOffRemorse.destroy()
            }
            root._bluetoothOffRemorse = remorseComponent.createObject(root)
            root._bluetoothOffRemorse.execute()
        }
    }

    Nemo.Notification {
        id: bluetoothEnabledNotification

        appIcon: "icon-s-bluetooth"
        urgency: Nemo.Notification.Critical
        isTransient: true

        //% "Turning Bluetooth on"
        body: qsTrId("lipstick-jolla-home-la-bluetoothon")
    }

    BluetoothPairing {
        id: pairing

        onRequestAccepted: lipstickService.call("replyToAgentRequest", [requestId, BluezQt.PendingCall.NoError, passkey])
        onRequestRejected: lipstickService.call("replyToAgentRequest", [requestId, BluezQt.PendingCall.AuthenticationRejected, ""])
        onInitiatiatedRequestCanceled: lipstickService.call("cancelPairWithDevice", [address])
    }

    DBusInterface {
        id: lipstickService
        service: "com.jolla.lipstick"
        path: "/bluetooth"
        iface: "com.jolla.lipstick"
    }

    DBusAdaptor {        
        service: "com.jolla.Bluetooth"
        path: "/agent_ui"
        iface: "com.jolla.Bluetooth"

        signal initiatedPairingRequest(string deviceAddress, string deviceName)
        signal agentPairingAction(string deviceAddress, string deviceName, int action, string passkey, int requestId)
        signal agentServiceAuthorizationAction(string deviceAddress, string deviceName, string uuid, int requestId)
        signal finishAction(int error)

        onInitiatedPairingRequest: {
            root.monitorManagerObjectChanges = true
            pairing.initiatedPairingRequest(deviceAddress, deviceName)
        }

        onAgentPairingAction: {
            root.monitorManagerObjectChanges = true
            pairing.agentPairingAction(deviceAddress, deviceName, action, passkey, requestId)
        }

        onAgentServiceAuthorizationAction: {
            root.monitorManagerObjectChanges = true
            root._agentServiceAuthorizationRequest(deviceAddress, deviceName, uuid, requestId)
        }

        onFinishAction: {
            root.monitorManagerObjectChanges = false
            if (pairing.finishPairing(error)) {
                return
            }
            if (_finishServiceAuthorization()) {
                return
            }
        }
    }

    Binding {
        target: bluetoothManager
        property: "monitorObjectManagerInterfaces"
        value: root.monitorManagerObjectChanges
    }
}
