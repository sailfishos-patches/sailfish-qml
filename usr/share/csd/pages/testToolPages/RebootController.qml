/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import org.nemomobile.dbus 2.0
import org.nemomobile.configuration 1.0
import ".."

Item {
    id: rebootController

    property bool completed
    property bool aborted

    property bool runInTests
    property double initialTestTime

    property alias running: testData.running
    property alias iterations: testData.iterations
    property alias testMode: testData.testMode
    property alias continuousTesting: testData.continuousTesting
    property alias path: testData.path
    property alias rebootTimer: rebootTimer

    property double testTime: {
        var n = new Date
        return n.valueOf() - testData.startTime
    }

    property double remainingTestTime: Math.max(_TEST_TIME*60 - (testData.running ? testTime : 0) / 1000, 0)

    // Test time in minutes
    readonly property double _TEST_TIME: {
        if (rebootController.runInTests)
            return testData.running ? testData.testTime : rebootController.initialTestTime
        else
            return 20
    }
    readonly property double _TEST_SUCCESS_ITERATIONS: Math.ceil(_TEST_TIME/2)
    readonly property int _TEST_REBOOT_DELAY: 5     // Reboot delay in seconds

    signal testResult(bool passed)
    signal testStopped(bool aborted)
    signal testFailed

    function unlock() {
        mce.unlock()
    }

    function reboot() {
        dsme.reboot()
    }

    function start() {
        var n = new Date
        testData.startTime = n.valueOf()
        testData.iterations = 0
        testData.testTime = _TEST_TIME
        testData.running = true
        systemd.enableAutostart(function(containsInstallInfo, changes) {
            if (containsInstallInfo)
                rebootTimer.start()
            else
                rebootController.fail()
        },
        rebootController.fail)
    }

    function step() {
        unlock()

        testData.iterations += 1

        rebootController.testResult(true)

        if (remainingTestTime === 0) {
            stop()
        } else {
            rebootTimer.restart()
        }

        testData.sync()
    }

    function stop(abort) {
        abort = !!abort
        rebootTimer.stop()
        systemd.disableAutostart(undefined, rebootController.fail)
        testData.running = false
        rebootController.completed = true
        rebootController.aborted = abort
        rebootController.testStopped(abort)
    }

    function fail() {
        rebootTimer.stop()
        testData.running = false
        rebootController.completed = true

        rebootController.testFailed()
    }

    DBusInterface {
        id: mce

        service: "com.nokia.mce"
        iface: "com.nokia.mce.request"
        path: "/com/nokia/mce/request"
        bus: DBus.SystemBus

        function unlock() {
            typedCall("req_tklock_mode_change", { "type": "s", "value": "unlocked" }, undefined, rebootController.fail)
        }
    }

    DBusInterface {
        id: dsme

        service: "com.nokia.dsme"
        iface: "com.nokia.dsme.request"
        path: "/com/nokia/dsme/request"
        bus: DBus.SystemBus

        function reboot() {
            typedCall("req_reboot", undefined, undefined, rebootController.fail)
        }
    }

    AppAutoStart {
        id: systemd
    }

    Timer {
        id: rebootTimer

        property int count: rebootController._TEST_REBOOT_DELAY

        interval: 1000
        repeat: true

        onTriggered: {
            if (count > 0) {
                --count
            } else {
                stop()
                count = rebootController._TEST_REBOOT_DELAY
                dsme.reboot()
            }
        }
    }

    ConfigurationGroup {
        id: testData

        property bool running
        property double startTime
        property int iterations
        property int testMode
        property bool continuousTesting
        property int testTime

        path: "/apps/csd/reboot"
    }
}
