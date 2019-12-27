/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Csd 1.0
import org.nemomobile.systemsettings 1.0

Page {
    id: page

    property bool disclaimerShown

    onStatusChanged: {
        if (status === PageStatus.Activating && !disclaimerShown && disclaimerText !== "") {
            pageStack.push(Qt.resolvedUrl("Disclaimer.qml"), {}, PageStackAction.Immediate)
            disclaimerShown = true
        }
    }

    TestCaseListModel {
        id: autoModel
        objectName: "autoTestsModel"
        autoTests: true
    }

    property var autoTests: { "" : "" }

    Component.onCompleted: {
        for (var i = 0; i < autoModel.count; ++i) {
            var autoTest = autoModel.get(i)

            if (autoTest.result == 1) {
                // Skip already passed tests.
                continue;
            }

            var url = autoTest.url
            var component = Qt.createComponent("testToolPages/" + url + "AutoTest.qml")
            if (component.status != Component.Ready) {
                console.log(component.errorString())
                continue
            }

            var incubator = component.incubateObject()

            // make sure the incubators are not garbage collected when this function returns
            autoTests[url] = incubator

            if (incubator.status == Component.Ready) {
                runAutoTest(url, incubator.object)
            } else {
                incubator.onStatusChanged = function(url, incubator) { return function(status) {
                    if (status == Component.Ready) {
                        runAutoTest(url, incubator.object)
                    }
                } }(url, incubator)
            }
        }
    }

    function runAutoTest(url, test) {
        test.testFinished.connect(function(passFail) {
            autoModel.setResult(url, passFail)
            test.destroy()
        })
        test.run()
        autoTests[url] = null
    }

    AboutSettings {
        id: aboutSettings
    }

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        anchors.fill: parent

        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: parent.width

            PageHeader {
                //% "CSD Tool"
                title: qsTrId("csd-he-csd_tool")

                //: Sailfish OS (version)
                //% "Sailfish OS %1"
                description: qsTrId("csd-la-sailfish_os_version").arg(aboutSettings.softwareVersionId)
            }

            SectionHeader {
                //% "Factory tests"
                text: qsTrId("csd-he-factory_tests")
            }

            TestPageItem {
                //% "Individual tests"
                text: qsTrId("csd-la-individual_tests")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("HardwareTestingPage.qml"),
                                                  { "testMode": Features.FactoryTests })
            }

            TestPageItem {
                //% "Continuous testing"
                text: qsTrId("csd-he-continuous_testing")
                onClicked: {
                    pageStack.animatorPush(Qt.resolvedUrl("HardwareTestingPage.qml"),
                                           { "continuousTesting": true, "testMode": Features.FactoryTests })
                }
            }

            TestPageItem {
                //% "Run-in tests"
                text: qsTrId("csd-la-runin_tests")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("RunInTestPage.qml"))
            }

            SectionHeader {
                //% "Hardware tests"
                text: qsTrId("csd-la-hardware_tests")
            }

            TestPageItem {
                //% "All tests"
                text: qsTrId("csd-la-all_tests")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("HardwareTestingPage.qml"))
            }

            SectionHeader {
                //% "Sensor calibration"
                text: qsTrId("csd-he-sensor-calibration")
                visible: proximityCalibration.visible || accelerometerCalibration.visible
            }

            TestPageItem {
                id: proximityCalibration

                visible: SensorCalibrationResolver.exists("proximity")
                //% "Proximity calibration"
                text: qsTrId("csd-he-proximity_calibration")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("testToolPages/CalibrationProxSensor.qml"))
            }

            TestPageItem {
                id: accelerometerCalibration

                visible: SensorCalibrationResolver.exists("accelerometer")
                text: {
                    if (Features.supported("Gyro") && Features.supported("GSensor")) {
                        //% "Gyro & Acceleromete calibration"
                        return qsTrId("csd-li-gyroscope_and_gsensor_calibration")
                    }
                    if (Features.supported("Gyro")) {
                        //% "Gyroscope calibration"
                        return qsTrId("csd-li-gyroscope_sensor_calibration")
                    }
                    //% "Accelerometer calibration"
                    return qsTrId("csd-li-accelerometer_sensor_calibration")
                }
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("testToolPages/CalibrationGyroAndGSensor.qml"))
            }

            SectionHeader {
                //% "Device status"
                text: qsTrId("csd-he-device_status")
            }

            TestPageItem {
                id: deviceStatus

                //% "Device status"
                text: qsTrId("csd-la-device_status")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("statusPages/DeviceStatus.qml"))
            }

            TestPageItem {
                //% "Power consumers"
                text: qsTrId("csd-la-power_consumers")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("statusPages/PowerConsumers.qml"))
            }

            Item { width: 1; height: Theme.paddingLarge }
        }
    }

    RadioPreference {
        id: radioPreference
    }
}
