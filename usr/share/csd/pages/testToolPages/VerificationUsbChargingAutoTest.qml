/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Csd 1.0
import Nemo.Mce 1.0
import ".."

AutoTest {
    id: test

    property bool started
    property bool completed
    property bool isTimeOut

    function run() {
        started = true
        test.evaluateTestStatus()
    }

    function completeTest(status) {
        if (status != undefined) {
            setTestResult(status)
        }
        completed = true
        timer.stop()
    }

    function evaluateTestStatus() {
        if (!started || completed) {
            // nop
        } else if (!battery.present()) {
            completeTest(undefined)
        } else if (!mceChargerType.connected) {
            timer.stop()
        } else if (mceBatteryState.value === MceBatteryState.Full) {
            completeTest(undefined)
        } else if (mceBatteryState.value === MceBatteryState.Charging) {
            completeTest(true)
        } else if (isTimeOut) {
            completeTest(false)
        } else {
            timer.start()
        }
    }

    Timer {
        id: timer

        interval: 3000
        onTriggered: {
            isTimeOut = true
            test.evaluateTestStatus()
        }
    }

    MceBatteryState {
        id: mceBatteryState

        onValueChanged: test.evaluateTestStatus()
    }

    MceChargerType {
        id: mceChargerType

        readonly property var usbTypes: [ MceChargerType.USB, MceChargerType.DCP, MceChargerType.HVDCP, MceChargerType.CDP ]
        property bool connected: usbTypes.indexOf(type) != -1
        onConnectedChanged: test.evaluateTestStatus()
    }

    Battery {
        id: battery
    }

    Timer {
        interval: 10000
        running: test.started && !test.completed
        onTriggered: test.completeTest(undefined)
    }
}
