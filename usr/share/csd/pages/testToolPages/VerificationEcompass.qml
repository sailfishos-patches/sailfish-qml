/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtSensors 5.0
import ".."

CsdTestPage {
    id: page
    readonly property real passingCalibrationLevel: 1
    property bool testPassed
    readonly property int testDuration: 25
    readonly property int testSubsampleRate: 4
    property int testRemainingSamples: testDuration * testSubsampleRate
    readonly property int testRemainingTime: testRemainingSamples / testSubsampleRate
    readonly property bool testRunning: !testPassed && testRemainingSamples > 0

    onTestRunningChanged: {
        if (!testRunning) {
            setTestResult(testPassed)
            testCompleted(false)
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height + Theme.paddingLarge

        VerticalScrollDecorator {
            Component.onCompleted: showDecorator()
        }

        Column {
            id: contentColumn
            width: parent.width
            spacing: Theme.paddingLarge
            CsdPageHeader {
                //% "Compass sensor"
                title: qsTrId("csd-he-compass_sensor")
            }
            DescriptionItem {
                //% "1. Please wave your device in a figure 8 for 5-20 seconds to calibrate the sensor."
                text: qsTrId("csd-la-compass_description")
            }

            SectionHeader {
                //% "Compass test result"
                text: qsTrId("csd-he-compass_test_result")
            }

            Label {
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap
                x: Theme.paddingLarge
                text:  //% "Pass calibration level: %0"
                       qsTrId("csd-la-pass_calibration_level").arg(page.passingCalibrationLevel) +
                       //% "Current calibration level: %0"
                       "\n\n" + qsTrId("csd-la-calibration_level").arg(compassSubsampleTimer.calibrationLevel) +
                       //% "Current azimuth: %0"
                       "\n\n" + qsTrId("csd-la-azimuth").arg(compassSubsampleTimer.azimuth)
            }

            Label {
                x: Theme.paddingLarge
                visible: !page.testRunning
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraLarge
                font.family: Theme.fontFamilyHeading
                color: page.testPassed ? "green" : "red"
                text: {
                    if (page.testPassed) {
                        //% "Pass"
                        return qsTrId("csd-la-pass")
                    }
                    //% "Fail"
                    return qsTrId("csd-la-fail")
                }
            }

            Label {
                visible: page.testRunning
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap
                x: Theme.paddingLarge
                text: //% "Checking compass..."
                      qsTrId("csd-la-checking_compass") + "\n\n" +
                      //% "Time remaining: %1"
                      qsTrId("csd-la-compass_timer %1").arg(page.testRemainingTime)
            }
        }
    }

    Timer {
        id: compassSubsampleTimer
        property real calibrationLevel
        property real azimuth
        interval: 1000 / page.testSubsampleRate
        running: page.status == PageStatus.Active
        repeat: true
        onTriggered: {
            calibrationLevel = compassSensor.calibrationLevel
            azimuth = compassSensor.azimuth
            if (page.testRemainingSamples > 0) {
                if (calibrationLevel >= page.passingCalibrationLevel) {
                    page.testPassed = true
                    page.testRemainingSamples = 0
                }  else {
                    page.testRemainingSamples -= 1
                }
            }
        }
    }

    Compass {
        id: compassSensor
        /* Test code change history suggests that a relatively high datarate
         * is needed for the actual calibration at lower SW levels to complete
         * in expected manner / time. However, we do not want to reevaluate
         * test status / update screen at such pace. Therefore: cache the
         * latest sensor values seen in here and then use timer to subsample
         * at pace that makes sense for test logic / updating ui elements. */
        dataRate: 100
        property real calibrationLevel
        property real azimuth
        active: page.status == PageStatus.Active
        onReadingChanged: {
            calibrationLevel = reading.calibrationLevel
            azimuth = reading.azimuth
        }
    }
}
