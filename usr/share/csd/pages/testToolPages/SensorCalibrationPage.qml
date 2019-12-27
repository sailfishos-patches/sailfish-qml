/*
 * Copyright (c) 2017 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."
import Csd 1.0

CsdTestPage {
    id: csdTestPage

    property alias sensor: sensorCalibration.sensor
    property alias type: sensorCalibration.type
    property alias title: header.title
    property alias description: description.text

    SensorCalibration {
        id: sensorCalibration
    }

    CsdPageHeader {
        id: header
    }

    Column {
        anchors.top: header.bottom
        width: parent.width
        spacing: Theme.paddingLarge

        DescriptionItem {
            id: description
        }

        Label {
            x: Theme.horizontalPageMargin
            width: Math.min(parent.width - x * 2, implicitWidth)
            text: sensorCalibration.representation.trim()
        }

        ResultLabel {
            id: resultLabel
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * x
            visible: false
            text: result ?
                      //% "Calibration successful"
                      qsTrId("csd-la-calibration_successful") :
                      //% "Calibration failed"
                      qsTrId("csd-la-calibration_failed")

        }
    }

    Column {
        width: parent.width
        anchors {
            bottom: parent.bottom
            bottomMargin: Theme.paddingLarge
        }

        Button {
            x: Theme.horizontalPageMargin
            width: parent.width - x * 2
            height: Theme.itemSizeMedium

            //% "Calibrate"
            text: qsTrId("csd-la-calibrate")
            enabled: sensorCalibration.enabled
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                var res = sensorCalibration.calibrate()
                resultLabel.result = res
                resultLabel.visible = true
                setTestResult(res)
                testCompleted(false)
            }
        }

        Button {
            x: Theme.horizontalPageMargin
            width: parent.width - x * 2
            height: Theme.itemSizeMedium



            //% "Clear calibration data"
            text: qsTrId("csd-la-clear_calibration_data")
            enabled: sensorCalibration.enabled
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                sensorCalibration.reset()
                resultLabel.visible = false
            }
        }

        Button {
            x: Theme.horizontalPageMargin
            width: parent.width - x * 2
            height: Theme.itemSizeMedium

            //% "Restore"
            text: qsTrId("csd-la-restore")
            enabled: sensorCalibration.enabled
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                sensorCalibration.restore()
                resultLabel.visible = false
            }
        }
    }
}
