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
    property bool result: compass.level === 1
    property real passingCalibrationLevel: 1

    function showPassOrFail() {
        if (page.result || timer.count == 25) {
            timer.running = false
            compass.active = false
            setTestResult(page.result)
            testCompleted(false)
        }

        timer.count = timer.count + 1
    }

    Compass {
        id: compass
        dataRate: 100
        active:true
        property real level

        onReadingChanged: {
            level = compass.reading.calibrationLevel
            if (compass.reading.calibrationLevel === 1) {
                timer.stop()
                compass.active = false
                page.showPassOrFail()
            }
        }
    }

    Column {
        id: column1

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
    }

    Column {
        id: column2
        width: page.width
        spacing: Theme.paddingLarge
        anchors.top: column1.bottom

        CsdPageHeader {
            //% "Compass test result"
            title: qsTrId("csd-he-compass_test_result")
        }

        Label {
            id: description
            visible: timer.running
            width: parent.width - 2*Theme.paddingLarge
            wrapMode: Text.Wrap
            x: Theme.paddingLarge
            //% "Checking compass..."
            text: qsTrId("csd-la-checking_compass") + "\n\n" +
                  //% "Time remaining: %1"
                  qsTrId("csd-la-compass_timer %1").arg(25 - timer.count)
        }

        Label {
            id: resultLabel
            width: parent.width - 2*Theme.paddingLarge
            wrapMode: Text.Wrap
            x: Theme.paddingLarge
            text:  //% "Pass calibration level: %0"
                   qsTrId("csd-la-pass_calibration_level").arg(page.passingCalibrationLevel) +
                   //% "Current calibration level: %0"
                   "\n\n" + qsTrId("csd-la-calibration_level").arg(compass.level)
        }

        Label {
            id: label
            x: Theme.paddingLarge
            visible: !timer.running
            width: parent.width - 2*Theme.paddingLarge
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeExtraLarge
            font.family: Theme.fontFamilyHeading
            color: page.result ? "green" : "red"
            //% "Pass"
            text: page.result ? qsTrId("csd-la-pass")
                              :  //% "Fail"
                                qsTrId("csd-la-fail")
        }
    }

    Timer {
        id: timer
        property int count
        interval: 1000
        running: true
        repeat: true
        onTriggered: page.showPassOrFail()
    }
}
