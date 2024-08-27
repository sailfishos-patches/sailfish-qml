/****************************************************************************
**
** Copyright (C) 2016 Jolla Ltd.
** Contact: Bea Lam <bea.lam@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.6
import QtQuick.Window 2.0
import Sailfish.Silica 1.0
import Sailfish.Bluetooth 1.0
import Nemo.Notifications 1.0 as Nemo
import org.kde.bluezqt 1.0 as BluezQt

ApplicationWindow {
    id: root

    property int _requestId: -1
    property QtObject _pairingWindow
    property bool _windowVisible: _pairingWindow && _pairingWindow.windowVisible

    signal requestAccepted(int requestId, string passkey)
    signal requestRejected(int requestId)
    signal initiatiatedRequestCanceled(string address)
    signal done()

    function initiatedPairingRequest(deviceAddress, deviceName) {
        _createPairingWindow()
        _pairingWindow.initiatedPairingRequest(deviceAddress, deviceName)
    }

    // Process a pairing information/confirmation request from the agent. Note the agent triggers
    // this for both pairing requests initiated by this device and those received from other devices.
    // Also note requestId is not set for DisplayPin and DisplayPasskey requests.
    function agentPairingAction(deviceAddress, deviceName, action, passkey, requestId) {
        if (requestId >= 0) {
            _requestId = requestId
        }
        _createPairingWindow()
        _pairingWindow.agentAction(deviceAddress, deviceName, action, passkey)
    }

    function finishPairing(error) {
        if (_windowVisible && _pairingWindow.finishPairing(_pairingErrorToText(error))) {
            _requestId = -1
            return true
        }
        return false
    }

    function _createPairingWindow() {
        if (_pairingWindow) {
            return
        }
        var comp = Qt.createComponent(Qt.resolvedUrl("BluetoothPairingWindow.qml"))
        if (comp.status == Component.Error) {
            console.log("BluetoothPairingWindow.qml error:", comp.errorString())
            return
        }
        _pairingWindow = comp.createObject(root)
        _pairingWindow.done.connect(function() {
            root.done()
            root._requestId = -1
        })
        _pairingWindow.pairingAccepted.connect(function() {
            if (root._requestId >= 0) {
                root.requestAccepted(root._requestId, root._pairingWindow.enteredPasskey)
                root._requestId = -1
            }
        })
        _pairingWindow.pairingRejected.connect(function() {
            if (root._requestId >= 0) {
                root.requestRejected(root._requestId)
                root._requestId = -1
            } else {
                root.initiatiatedRequestCanceled(_pairingWindow.deviceAddress)
            }
        })
    }

    function _pairingErrorToText(error) {
        switch (error) {
        case BluezQt.PendingCall.NoError:
            return ""
        case BluezQt.PendingCall.Canceled:
        case BluezQt.PendingCall.AuthenticationCanceled:
            //: Shown when a Bluetooth pairing operation is canceled
            //% "The pairing operation was canceled."
            return qsTrId("lipstick-jolla-home-la-pairing_canceled")
        case BluezQt.PendingCall.AuthenticationFailed:
            //: Shown when a bluetooth pairing was attempted but the passkeys did not match
            //% "Pairing authentication failed. The passkeys did not match."
            return qsTrId("lipstick-jolla-home-la-pairing_error_passkey_mismatch")
        case BluezQt.PendingCall.AuthenticationRejected:
            //: Shown when a bluetooth pairing was attempted but the other device rejected the request
            //% "The pairing request was denied."
            return qsTrId("lipstick-jolla-home-la-pairing_error_rejected")
        case BluezQt.PendingCall.ConnectFailed:
        case BluezQt.PendingCall.ConnectionAttemptFailed:
            //: Shown when a bluetooth pairing was attempted but we were unable to connect to the other device
            //% "Could not connect to the other device. Make sure it has Bluetooth enabled and try again."
            return qsTrId("lipstick-jolla-home-la-pairing_error_connection_failed")
        case BluezQt.PendingCall.DBusError:
        case BluezQt.PendingCall.AuthenticationTimeout:
            //: Shown when a bluetooth pairing was attempted but there was no response from the other device
            //% "The other device did not respond to the pairing request."
            return qsTrId("lipstick-jolla-home-la-pairing_error_timeout")
        default:
            //: Generic error description shown when a bluetooth pairing attempt failed
            //% "The pairing could not be created."
            return qsTrId("lipstick-jolla-home-la-pairing_error_unknown")
        }
    }
}
