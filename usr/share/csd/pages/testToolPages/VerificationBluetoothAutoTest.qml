/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Bluetooth 1.0
import org.kde.bluezqt 1.0 as BluezQt
import ".."

AutoTest {
    property bool testStarted
    property QtObject adapter: BluezQt.Manager
                               ? BluezQt.Manager.usableAdapter
                               : null

    function run() {
        bluetoothTechModel.initTestCase()
        testStarted = true
        timeoutTimer.start()
        _triggerDiscovery()
    }

    function _triggerDiscovery() {
        if (testStarted && !bluetoothTechModel.testFinished
                && adapter && adapter.powered && !adapter.discovering) {
            adapter.startDiscovery()
        }
    }

    onAdapterChanged: {
        if (!!adapter) {
            bluetoothTechModel.wasInitiallyPowered = adapter.powered
            _triggerDiscovery()
        }
    }

    VerificationTechnologyModel {
        id: bluetoothTechModel

        name: "bluetooth"

        onFinished: {
            if (!!adapter) {
                adapter.stopDiscovery()
                adapter.powered = wasInitiallyPowered
                setTestResult(success)
            }
        }

        onAvailableChanged: {
            if (available) {
                console.time("bluetooth-device-discovery")
            }
        }
    }

    Timer {
        id: timeoutTimer
        interval: 30000
        onTriggered: bluetoothTechModel.done(false)
    }

    Connections {
        target: adapter

        onPoweredChanged: _triggerDiscovery()
        onDiscoveringChanged: _triggerDiscovery()
    }

    Connections {
        target: BluezQt.Manager
        onDeviceAdded: {
            console.log("Bluetooth device found:", device.address)
            if (adapter && !adapter.discovering) {
                // Devices are added when the manager is first loaded, but we only want to end the
                // test when devices are found during device discovery.
                return
            }
            bluetoothTechModel.done(true)
            console.timeEnd("bluetooth-device-discovery")
        }
    }
}
