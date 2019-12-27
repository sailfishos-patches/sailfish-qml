/*
 * Copyright (c) 2018 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Csd 1.0
import ".."

CsdTestPage {
    id: page

    function isCalibrated() {
        return calibrationTest.isCalibrationFlagOk() && calibrationTest.isCalibrationStringOk()
    }

    Component.onDestruction: {
        page.setTestResult(isCalibrated())
        testCompleted(false)
    }

    Column {
        CsdPageHeader {
            //% "Calibration"
            title: qsTrId("csd-he-calibration")
        }

        ResultLabel {
            id: testResult

            x: Theme.horizontalPageMargin
            width: parent.width - 2*x

            result: isCalibrated()
        }

        SectionHeader {
            //% "Calibration Flag"
            text: qsTrId("csd-he-calibration-flag")
        }

        Label {
            x: Theme.paddingLarge
            width: page.width - (2 * Theme.paddingLarge)
            wrapMode: Text.Wrap

            color: calibrationTest.isCalibrationFlagOk()
                   ? "green"
                   : "red"

            text: calibrationTest.isCalibrationFlagOk()
                    //% "Test passed."
                    ? qsTrId("csd-la-test-passed")
                    //% "Test failed."
                    : qsTrId("csd-la-test-failed")
        }

        Label {
            x: Theme.paddingLarge
            width: page.width - (2 * Theme.paddingLarge)
            wrapMode: Text.Wrap

            //% "Value: %1"
            text: qsTrId("csd-la-value").arg(calibrationTest.calibrationFlag)
        }

        Label {
            x: Theme.paddingLarge
            width: page.width - (2 * Theme.paddingLarge)
            fontSizeMode: Text.HorizontalFit

            visible: !calibrationTest.isCalibrationFlagOk()

            //% "Acceptance criteria: %1"
            text: qsTrId("csd-la-acceptance-criteria").arg(calibrationTest.calibrationFlagCriteria)
        }

        SectionHeader {
            //% "Calibration String"
            text: qsTrId("csd-he-calibration-string")
        }

        Label {
            x: Theme.paddingLarge
            width: page.width - (2 * Theme.paddingLarge)
            wrapMode: Text.Wrap

            color: calibrationTest.isCalibrationStringOk()
                   ? "green"
                   : "red"

            text: calibrationTest.isCalibrationStringOk()
                    //% "Test passed."
                    ? qsTrId("csd-la-test-passed")
                    //% "Test failed."
                    : qsTrId("csd-la-test-failed")
        }

        Label {
            x: Theme.paddingLarge
            width: page.width - (2 * Theme.paddingLarge)
            wrapMode: Text.Wrap

            //% "Value: %1"
            text: qsTrId("csd-la-value").arg(calibrationTest.calibrationString)
        }

        Label {
            x: Theme.paddingLarge
            width: page.width - (2 * Theme.paddingLarge)
            fontSizeMode: Text.HorizontalFit

            visible: !calibrationTest.isCalibrationStringOk()

            //% "Acceptance criteria: %1"
            text: qsTrId("csd-la-acceptance-criteria").arg(calibrationTest.calibrationStringCriteria)
        }
    }

    CalibrationTest {
        id: calibrationTest
    }
}

