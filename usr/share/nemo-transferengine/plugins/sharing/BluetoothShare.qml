/****************************************************************************************
**
** Copyright (c) 2013 - 2021 Jolla Ltd.
** Copyright (c) 2021 Open Mobile Platform LLC.
** All rights reserved.
**
** License: Proprietary.
**
****************************************************************************************/
import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.TransferEngine 1.0
import Sailfish.Bluetooth 1.0
import Sailfish.Policy 1.0
import com.jolla.settings.system 1.0

Column {
    id: root

    property var shareAction

    readonly property bool _isPortrait: __silica_applicationwindow_instance.orientation === Qt.PortraitOrientation
                                        || __silica_applicationwindow_instance.orientation === Qt.InvertedPortraitOrientation

    width: parent.width
    height: mdmBanner.active ? mdmBanner.height * 2 : devicePicker.height

    Component.onCompleted: {
        session.startSession()
        sailfishTransfer.loadConfiguration(shareAction.toConfiguration())
    }

    Component.onDestruction: {
        session.endSession()
    }

    BluetoothSession {
        id: session
    }

    SailfishTransfer {
        id: sailfishTransfer
    }

    BluetoothDevicePicker {
        id: devicePicker

        height: Math.max(implicitHeight, _isPortrait ? Screen.height : Screen.width)

        autoStartDiscovery: !mdmBanner.active
        openMenuOnPressAndHold: false
        visible: !mdmBanner.active

        onDeviceClicked: {
            devicePicker.stopDiscovery()
            sailfishTransfer.userData = { deviceAddress: devicePicker.selectedDevice }
            sailfishTransfer.start()
            shareAction.done()
        }
    }

    DisabledByMdmBanner {
        id: mdmBanner

        active: !AccessPolicy.bluetoothToggleEnabled
    }
}
