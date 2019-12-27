/*
 * Copyright (c) 2015 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0
import Nemo.KeepAlive 1.2
import ".."

CsdTestPage {
    id: page

    property bool completed

    Component.onCompleted: {
        if (runInTests)
            testController.start()
    }

    Column {
        width: parent.width
        spacing: Theme.paddingLarge

        CsdPageHeader {
            //% "Suspend"
            title: qsTrId("csd-he-suspend")
        }

        DescriptionItem {
            //% "Device will suspend and wake up periodically for %1 minutes.<br/><br/>1. Disconnect USB cable.<br/>2. Press 'Start' to begin."
            text: qsTrId("csd-la-suspend_test_description").arg(testController._TEST_TIME)
        }

        SectionHeader {
            //% "Statistics"
            text: qsTrId("csd-he-test_stats")
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x

            //% "Remaining: %1"
            text: qsTrId("csd-la-test_time_remaining").arg(Format.formatDuration(testController.remainingTestTime, Format.DurationShort))
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x

            //% "Iterations: %1"
            text: qsTrId("csd-la-iterations").arg(testController.iterations)
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x

            //% "Suspend time: %1"
            text: qsTrId("csd-la-suspend_time").arg(Format.formatDuration(testController.testSuspendTime, Format.DurationShort))
        }

        ResultLabel {
            id: testResult

            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            visible: page.completed
        }
    }

    BottomButton {
        id: startButton

        visible: !runInTests && !testController.testing

        //% "Start"
        text: qsTrId("csd-la-start")

        onClicked: testController.start()
    }

    QtObject {
        id: testController

        property bool testing

        property double initialUpTime
        property double currentUpTime
        readonly property double remainingTestTime: Math.max(_TEST_TIME * 60 - (currentUpTime - initialUpTime) / 1000, 0)

        property double initialSuspendTime
        property double currentSuspendTime
        readonly property double testSuspendTime: (currentSuspendTime - initialSuspendTime) / 1000

        property int iterations

        // Test time in minutes
        property double _TEST_TIME: page.runInTests
                                    ? page.parameters["RunInTestTime"] : 20

        function start() {
            testing = true

            mce.getSuspendStats(function(upTime, suspendTime) {
                                    initialUpTime = upTime
                                    currentUpTime = upTime
                                    initialSuspendTime = suspendTime
                                    currentSuspendTime = suspendTime
                                })
            wakeup.enabled = true
            offTimer.start()
        }

        function step() {
            mce.turnOnDisplay()
            mce.getSuspendStats(function(upTime, suspendTime) {
                if (wakeup.filtering) {
                    wakeup.filtering = false
                    offTimer.restart()
                    return
                }

                if (runInTests) {
                    // Pass test if suspend time has increased.
                    setTestResult(suspendTime > currentSuspendTime)
                }

                currentUpTime = upTime
                currentSuspendTime = suspendTime
                iterations += 1

                if (remainingTestTime === 0) {
                    stop()
                } else {
                    offTimer.restart()
                }
            })
        }

        function stop() {
            testing = false
            testResult.result = testSuspendTime > 0
            page.completed = true

            if (!runInTests) {
                setTestResult(testSuspendTime > 0)
            }
            testCompleted(false)
        }

        function fail() {
            testing = false
            testResult.result = false
            page.completed = true
            setTestResult(false)
            testCompleted(false)
        }
    }

    DBusInterface {
        id: mce

        service: "com.nokia.mce"
        iface: "com.nokia.mce.request"
        path: "/com/nokia/mce/request"
        bus: DBus.SystemBus

        function getSuspendStats(func) {
            typedCall("get_suspend_stats", undefined, func, testController.fail)
        }

        function turnOffDisplay() {
            typedCall("req_display_state_off", undefined, undefined, testController.fail)
        }

        function turnOnDisplay() {
            typedCall("req_tklock_mode_change", { "type": "s", "value": "unlocked" }, undefined, testController.fail)
            typedCall("req_display_state_on", undefined, undefined, testController.fail)
        }
    }

    BackgroundJob {
        id: wakeup

        property bool filtering: true

        enabled: false
        // The first wakeup can occur soon after scheduling. Thus, we do not treat the first
        // display on as a wakeup from suspend.
        frequency: BackgroundJob.ThirtySeconds * 2
        onTriggered: testController.step()
    }

    Timer {
        id: offTimer

        interval: 5000
        onTriggered: {
            mce.turnOffDisplay()
            wakeup.finished()
        }
    }
}
