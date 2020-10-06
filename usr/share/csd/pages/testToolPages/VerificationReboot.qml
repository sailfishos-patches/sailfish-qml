/*
 * Copyright (c) 2015 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

CsdTestPage {
    id: page

    Component.onCompleted: {
        testController.testMode = testMode
        testController.continuousTesting = isContinueTest
    }
    onStatusChanged: {
        if (status == PageStatus.Active) {
            if (testController.running)
                testController.step()
            else if (runInTests)
                testController.start()
        }
    }

    Column {
        width: parent.width
        spacing: Theme.paddingLarge

        CsdPageHeader {
            //% "Reboot"
            title: qsTrId("csd-he-reboot")
        }

        DescriptionItem {
            //% "Device will reboot periodically for %1 minutes.<br/><br/>1. Press 'Start' to begin."
            text: qsTrId("csd-la-reboot_test_description").arg(testController._TEST_TIME)
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
            text: qsTrId("csd-la-iterations").arg(testController.running || testController.completed ? testController.iterations : 0)
        }

        ResultLabel {
            id: testResult

            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            visible: testController.completed && !testController.aborted
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            visible: testController.rebootTimer.running

            //% "Rebooting in %1s"
            text: qsTrId("csd-la-reboot_count_down").arg(testController.rebootTimer.count)
        }
    }

    BottomButton {
        text: testController.running || runInTests
                //% "Abort"
              ? qsTrId("csd-la-abort")
                //% "Start"
              : qsTrId("csd-la-start")

        onClicked: {
            if (testController.running || runInTests)
                testController.stop(true)
            else
                testController.start()
        }
    }

    RebootController {
        id: testController
        path: "/apps/csd/reboot"
        runInTests: page.runInTests
        initialTestTime: page.runInTests
                         ? page.parameters["RunInTestTime"] : 20

        onTestResult: page.setTestResult(passed)
        onTestFailed: {
            testResult.result = false
            page.setTestResult(false)
            page.testCompleted(false)
        }
        onTestStopped: {
            testResult.result = !testController.aborted && testController.iterations > testController._TEST_SUCCESS_ITERATIONS
            page.testCompleted(aborted)
        }
    }
}
