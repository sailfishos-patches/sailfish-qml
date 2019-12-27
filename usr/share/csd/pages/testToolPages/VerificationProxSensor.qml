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

    property int countNear
    property int countFar
    property int passCriteria: 3
    property bool currentProximityValue

    Column {
        width: page.width

        CsdPageHeader {
            //% "Proximity sensor"
            title: qsTrId("csd-he-proximity_sensor")
        }
        DescriptionItem {
            id: guideText
            //% "1. Cover the proximity sensor<br>2. Uncover the proximity sensor<br>3. Repeat, step 1 and 2 three times<br>"
            text: qsTrId("csd-la-verification_proximity_sensor_description")
        }
        Label {
            id: resultText
            x: Theme.paddingLarge
            font.pixelSize: Theme.fontSizeMedium
            //% "Proximity sensor: %1"
            text: qsTrId("csd-la-verification_proxmity_sensor").arg(currentProximityValue
                                                                    //% "Covered"
                                                                    ? qsTrId("csd-la-proximity_sensor_covered")
                                                                      //% "Uncovered"
                                                                    : qsTrId("csd-la-proximity_sensor_uncovered"))
            visible: false
        }
        ResultLabel {
            id: passText
            x: Theme.paddingLarge
            visible: false
            result: true
        }
    }
    FailBottomButton {
        id: failButton
        onClicked: {
            setTestResult(false)
            testCompleted(false)
        }
    }
    ProximitySensor {
        id: proxSensor
        active: true
        onReadingChanged: {
            if (reading) {
                resultText.visible = true
                currentProximityValue = reading.near
                if (currentProximityValue) {
                    countNear++
                } else {
                    countFar++
                }
                if (countNear >= passCriteria && countFar >= passCriteria) {
                    setTestResult(true)
                    testCompleted(false)
                    failButton.visible = false
                    passText.visible = true
                }
            }
        }
    }
}
