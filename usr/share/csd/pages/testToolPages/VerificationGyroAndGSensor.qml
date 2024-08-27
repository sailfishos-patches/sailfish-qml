/*
 * Copyright (c) 2016 - 2023 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Csd 1.0
import ".."

CsdTestPage {
    id: page

    property bool runGyroTest: Features.supported("Gyro")
    property bool runGSensorTest: Features.supported("GSensor")

    property bool _runBothTests: runGyroTest && runGSensorTest
    property int _resultsColumnWidth: _runBothTests && orientation == Orientation.Landscape ? width/2 : width

    function _checkForFinished() {
        if ((!runGyroTest || gyroTest.done) && (!runGSensorTest || gSensorTest.done)) {
            setTestResult((!runGyroTest || gyroTest.testPassed) && (!runGSensorTest || gSensorTest.testPassed))
            testCompleted(false)
        }
    }

    // Workaround for string.arg(real) with zero format controls
    function rounded(val) {
        var sign = val < 0 ? "" : "+"
        return sign + val.toFixed(4)
    }

    GyroTest {
        id: gyroTest

        onDoneChanged: {
            if (done) {
                gyroResultLabel.result = testPassed
                _checkForFinished()
            }
        }
    }

    GSensorTest {
        id: gSensorTest

        onDoneChanged: {
            if (done) {
                gSensorResultLabel.result = testPassed
                _checkForFinished()
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height + Theme.paddingLarge

        VerticalScrollDecorator {}

        Column {
            id: contentColumn
            width: parent.width

            CsdPageHeader {
                title: {
                    if (_runBothTests) {
                        //% "Gyro & Accelerometer"
                        return qsTrId("csd-he-gyroscope_and_gsensor")
                    }
                    return runGyroTest
                              //% "Gyroscope sensor"
                            ? qsTrId("csd-he-gyroscope_sensor")
                              //% "Accelerometer sensor"
                            : qsTrId("csd-he-accelerometer_sensor")
                }
            }

            DescriptionItem {
                id: instructions
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                //% "1. Please put device on horizontal surface.<br>2. Press 'Start' to verify."
                text: qsTrId("csd-la-verification_gyro_description")
            }

            Flow {
                width: parent.width

                Column {
                    id: gyroResults
                    width: page._resultsColumnWidth
                    spacing: Theme.paddingLarge
                    visible: false

                    SectionHeader {
                        //% "Gyroscope sensor"
                        text: qsTrId("csd-he-gyroscope_sensor")
                        visible: page._runBothTests
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2*x
                        wrapMode: Text.Wrap
                        font.bold: true

                        //% "Sensor values:"
                        text: qsTrId("csd-la-sensor_values")
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2*x
                        wrapMode: Text.Wrap

                        //: X, Y and Z values of the Gyroscope sensor
                        //% "X: %1<br>Y: %2<br>Z: %3"
                        text: qsTrId("csd-la-gyro_output").arg(rounded(gyroTest.curX)).arg(rounded(gyroTest.curY)).arg(rounded(gyroTest.curZ))
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        //% "Sensor test started. Please wait %1 seconds for it to finish."
                        text: qsTrId("csd-la-gyroscope_test_started").arg(gyroTest.secondsRemaining)
                        width: parent.width - 2*x
                        font.bold: true
                        wrapMode: Text.Wrap
                        visible: gyroTest.running
                    }

                    ResultLabel {
                        id: gyroResultLabel
                        visible: gyroTest.done
                        x: Theme.horizontalPageMargin

                        text: (gyroResultLabel.result
                              //% "Pass"
                              ? qsTrId("csd-la-pass")
                              //% "Fail"
                              : qsTrId("csd-la-fail"))
                              + "\nX: %1".arg(rounded(gyroTest.avgX))
                              + "\nY: %1".arg(rounded(gyroTest.avgY))
                              + "\nZ: %1".arg(rounded(gyroTest.avgZ))
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2*x
                        wrapMode: Text.Wrap

                        //: Explanation of X, Y and Z values of the Gyroscope sensor
                        //% "Values for x, y and z axis cannot be zero and must be between %1 and %2."
                        text: qsTrId("csd-la-checking_gyro_minmax").arg(CsdHwSettings.gyroMin).arg(CsdHwSettings.gyroMax)
                    }
                }

                Column {
                    id: gSensorResults
                    width: page._resultsColumnWidth
                    spacing: Theme.paddingLarge
                    visible: false

                    SectionHeader {
                        //% "Accelerometer sensor"
                        text: qsTrId("csd-he-accelerometer_sensor")
                        visible: page._runBothTests
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2*x
                        wrapMode: Text.Wrap
                        font.bold: true

                        //% "Sensor values:"
                        text: qsTrId("csd-la-sensor_values")
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2*x
                        wrapMode: Text.Wrap
                        text: //% "Gx: %0 (min: %1, max: %2)"
                              qsTrId("csd-la-accelerometer_readings_x").arg(rounded(gSensorTest.curX)).arg(gSensorTest.minX).arg(gSensorTest.maxX) + "\n" +
                              //% "Gy: %0 (min: %1, max: %2)"
                              qsTrId("csd-la-accelerometer_readings_y").arg(rounded(gSensorTest.curY)).arg(gSensorTest.minY).arg(gSensorTest.maxY) + "\n" +
                              //% "Gz: %0 (min: %1, max: %2)"
                              qsTrId("csd-la-accelerometer_readings_z").arg(rounded(gSensorTest.curZ)).arg(gSensorTest.minZ).arg(gSensorTest.maxZ)


                    }

                    ResultLabel {
                        id: gSensorResultLabel
                        visible: gSensorTest.done
                        x: Theme.horizontalPageMargin

                        text: (gSensorResultLabel.result
                              //% "Pass"
                              ? qsTrId("csd-la-pass")
                              //% "Fail"
                              : qsTrId("csd-la-fail"))
                              //% "Gx: %0 (min: %1, max: %2)"
                              + "\n" + qsTrId("csd-la-accelerometer_readings_x").arg(rounded(gSensorTest.avgX)).arg(gSensorTest.minX).arg(gSensorTest.maxX)
                              //% "Gy: %0 (min: %1, max: %2)"
                              + "\n" + qsTrId("csd-la-accelerometer_readings_y").arg(rounded(gSensorTest.avgY)).arg(gSensorTest.minY).arg(gSensorTest.maxY)
                              //% "Gz: %0 (min: %1, max: %2)"
                              + "\n" + qsTrId("csd-la-accelerometer_readings_z").arg(rounded(gSensorTest.avgZ)).arg(gSensorTest.minZ).arg(gSensorTest.maxZ)
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2*x
                        wrapMode: Text.Wrap
                        visible: gSensorTest.done

                        //% "'Min' and 'max' on each line indicate the range of values that are acceptable to pass this test."
                        text: qsTrId("csd-la-following_gsensor_values_were_detected")
                    }
                }
            }
        }
    }

    BottomButton {
        id: startButton
        //% "Start"
        text: qsTrId("csd-la-start")
        onClicked: {
            visible = false
            instructions.visible = false
            if (runGyroTest) {
                gyroTest.start()
                gyroResults.visible = true
            }
            if (runGSensorTest) {
                gSensorTest.start()
                gSensorResults.visible = true
            }
        }
    }
}
