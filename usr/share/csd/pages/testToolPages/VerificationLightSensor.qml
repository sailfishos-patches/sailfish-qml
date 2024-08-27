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
    
    // TODO: We might want this to be configurable at some point of time?
    property int passCriteria: 100
    property int sensorDifference
    property int valueLow: -1
    property int valueHigh: -1
    property int currentLightValue

    readonly property int columnWidth: orientation == Orientation.Landscape ? width/2 : width

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height + Theme.paddingLarge

        VerticalScrollDecorator {}

        Column {
            id: contentColumn

            width: parent.width
            CsdPageHeader {
                //% "Light sensor"
                title: qsTrId("csd-he-light_sensor")
            }

            Flow {
                width: parent.width
                Column {
                    width: columnWidth
                    spacing: Theme.paddingLarge

                    DescriptionItem {
                        id: guideText
                        //% "1. Cover the light sensor <br>2. Uncover the sensor and put light source over it <br>"
                        text: qsTrId("csd-la-verification_light_sensor_description")
                    }
                    Label {
                        x: Theme.paddingLarge
                        //% "Lowest sensor value: %1<br>Highest sensor value: %2<br>Difference pass criteria: %3<br>Difference: %4<br>Current light value: %5"
                        text: qsTrId("csd-la-verification_light_sensor_value").arg(valueLow).arg(valueHigh).arg(passCriteria).arg(sensorDifference).arg(currentLightValue)
                    }
                }
                Column {
                    width: columnWidth
                    spacing: Theme.paddingLarge

                    ResultLabel {
                        id: passText
                        x: Theme.paddingLarge
                        visible: false
                        result: true
                    }

                    FailBottomButton {
                        id: failButton
                        anchors.bottom: undefined
                        anchors.bottomMargin: 0
                        onClicked: {
                            setTestResult(false)
                            testCompleted(true)
                        }
                    }
                }
            }
        }
    }

    LightSensor {
        id: lightSensor
        active: true
        onReadingChanged: {
            if (reading) {
                currentLightValue = reading.illuminance
                // In some cases the lowest value might be quite high if the ambient is bright
                // so lets make the first value the base value.
                if ( valueLow == -1 ) {
                    valueLow = valueHigh = currentLightValue
                }
                else if (currentLightValue > valueHigh) {
                    valueHigh = currentLightValue
                }
                else if (currentLightValue < valueLow) {
                    valueLow = currentLightValue
                }
                sensorDifference = valueHigh - valueLow
                if (sensorDifference !== 0 && sensorDifference >= passCriteria) {
                    failButton.visible = false
                    passText.visible = true
                    setTestResult(true)
                    testCompleted(false)
                    // Lets not stop sensor here so that the test can be used for testing different
                    // lighting conditions as well.
                }
            }
        }
    }
}
