/****************************************************************************
**
** Copyright (C) 2016 Jolla Ltd.
** Contact: Bea Lam <bea.lam@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import QtQuick.Window 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0
import com.jolla.lipstick 0.1

ApplicationWindow {
    id: root

    property IncomingFileConfirmationWindow _fileConfirmationWindow

    function _showIncomingFileWindow(transferPath, deviceAddress, deviceName, fileName) {
        if (!_fileConfirmationWindow) {
            var comp = Qt.createComponent(Qt.resolvedUrl("IncomingFileConfirmationWindow.qml"))
            if (comp.status == Component.Error) {
                console.log("BluetoothPairingWindow.qml error:", comp.errorString())
                transferManager.userConfirmationResult(transferPath, false)
                return
            }
            _fileConfirmationWindow = comp.createObject(root)
            _fileConfirmationWindow.done.connect(function(acceptFile) {
                transferManager.userConfirmationResult(transferPath, acceptFile)
                root._closeWindow()
            })
        }
        _fileConfirmationWindow.init(deviceAddress, deviceName, fileName)
    }

    function _closeWindow() {
        if (_fileConfirmationWindow
                && _fileConfirmationWindow.visibility != Window.Hidden) {
            _fileConfirmationWindow.lower()
        }
    }

    allowedOrientations: defaultAllowedOrientations
    _defaultPageOrientations: Orientation.All
    _defaultLabelFormat: Text.PlainText
    cover: undefined

    Timer {
        id: delayedQuit
        interval: 400   // wait for window fade outs etc.
        onTriggered: {
            console.log("lipstick-obex-ui: exiting...")
            Qt.quit()
        }
    }

    ObexTransferManager {
        id: transferManager

        onUserConfirmationRequested: {
            root._showIncomingFileWindow(transferPath, deviceAddress, deviceName, fileName)
        }

        onTransferCountChanged: {
            if (transferCount == 0) {
                delayedQuit.start()
            }
        }
    }

    DBusInterface {
        id: lipstickService
        service: "com.jolla.lipstick"
        path: "/bluetooth"
        iface: "com.jolla.lipstick"
    }

    DBusAdaptor {
        service: "com.jolla.obex"
        path: "/agent_ui"
        iface: "com.jolla.obex"

        signal authorizePush(string transferPath, string sessionPath, string fileName, string fileType, int fileSize, bool autoAcceptTransfer)
        signal transferStatusChanged(string transferPath, int status)
        signal transferProgressChanged(string transferPath, variant progress)   // variant not var, in order to receive quint64 value
        signal pendingTransferCanceled(string transferPath)

        onAuthorizePush: {
            transferManager.newTransferRequest(transferPath, sessionPath, fileName, fileType, fileSize, autoAcceptTransfer)
        }
        onTransferStatusChanged: {
            transferManager.transferStatusChanged(transferPath, status)
        }
        onTransferProgressChanged: {
            transferManager.transferProgressChanged(transferPath, progress)
        }
        onPendingTransferCanceled: {
            transferManager.pendingTransferCanceled(transferPath)
            _closeWindow()
        }
    }
}
