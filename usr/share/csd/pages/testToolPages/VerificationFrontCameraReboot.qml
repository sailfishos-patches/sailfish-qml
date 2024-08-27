/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import com.jolla.settings.system 1.0
import QtMultimedia 5.4
import ".."

CameraTestPage {
    id: page

    readonly property bool resumeTest: camera.imageCapture.ready && canActivateCamera

    imagePreview.mirror: true

    onResumeTestChanged: {
        if (resumeTest) {
            resumeTesting()
        }
    }

    customTestResultHandler: function(passFail) {
        page.testFinished(passFail)
        page.active = false
        rebootController.rebootTimer.start()
    }

    customTestCompletedHandler: function(popImmediately) {
        // Don't let camera test to pop the page.
    }

    onStatusChanged: {
        if (status == PageStatus.Active) {
            if (rebootController.running) {
                rebootController.step()
            } else if (runInTests) {
                rebootController.start()
            }
            rebootController.rebootTimer.stop()
        }
    }

    CsdPageHeader {
        id: header
        //% "Front camera with reboot"
        title: qsTrId("csd-he-front_camera_reboot")
    }

    DisabledByMdmBanner {
        id: mdmBanner
        anchors.top: header.bottom
        active: !cameraPolicy.value
        Timer {
            id: disabledByMdmFailTimer
            interval: 2500
            running: true
            onTriggered: {
                if (mdmBanner.active) {
                    setTestResult(false)
                    testCompleted(true)
                }
            }
        }
    }

    PolicyValue {
        id: cameraPolicy
        policyType: PolicyValue.CameraEnabled
    }

    Column {
        width: parent.width
        spacing: Theme.paddingLarge
        anchors.centerIn: parent
        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x

            //% "Remaining: %1"
            text: qsTrId("csd-la-test_time_remaining").arg(Format.formatDuration(rebootController.remainingTestTime, Format.DurationShort))
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x

            //% "Iterations: %1"
            text: qsTrId("csd-la-iterations").arg(rebootController.running || rebootController.completed ? rebootController.iterations : 0)
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            visible: rebootController.rebootTimer.running

            //% "Rebooting in %1s"
            text: qsTrId("csd-la-reboot_count_down").arg(rebootController.rebootTimer.count)
        }
    }

    BottomButton {
        id: abortButton
        visible: rebootController.running
        //% "Abort"
        text: qsTrId("csd-la-abort")

        onClicked: rebootController.stop(true)
    }

    RebootController {
        id: rebootController
        path: "/apps/csd/front_camera_reboot"
        runInTests: page.runInTests
        initialTestTime: page.parameters["RunInTestTime"]

        onTestFailed: {
            testResult.result = false
            page.active = false
            page.setTestResult(false)
            page.exit(false)
        }
        onTestStopped: {
            page.active = false
            page.exit(aborted)
        }
    }

    Component.onCompleted: {
        page.camera.position = Camera.FrontFace
        rebootController.testMode = testMode
        rebootController.continuousTesting = isContinueTest
    }
}
