/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Csd 1.0
import ".."

CsdTestPage {
    id: page

    onStatusChanged: {
        // check result after page has finished loading
        if (status === PageStatus.Active)
            testController.run()
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            anchors {
                left: parent.left
                leftMargin: Theme.paddingLarge
                right: parent.right
            }

            spacing: Theme.paddingSmall

            CsdPageHeader {
                //% "Battery"
                title: qsTrId("csd-he-battery")
            }

            Label {
                width: parent.width
                wrapMode: Text.Wrap
                visible: !testController.batteryPresent

                //% "Battery is not present"
                text: qsTrId("csd-la-battery_not_present")
            }

            Column {
                spacing: parent.spacing
                anchors {
                    left: parent.left
                    right: parent.right
                }
                visible: testController.batteryPresent && !isNaN(testController.voltageNow) && CsdHwSettings.batteryVoltageTest

                SectionHeader {
                    //% "Voltage"
                    text: qsTrId("csd-he-voltage")
                }

                Label {
                    //% "Minimum: %0V"
                    text: qsTrId("csd-la-minimum_voltage").arg(formatValue(testController.minimumVoltage, 1000000, 2))
                }

                Label {
                    //% "Maximum: %0V"
                    text: qsTrId("csd-la-maximum_voltage").arg(formatValue(testController.maximumVoltage, 1000000, 2))
                }

                Label {
                    //% "Value: %0V"
                    text: qsTrId("csd-la-voltage_value").arg(formatValue(testController.voltageNow, 1000000, 2))
                }

                ResultLabel {
                    result: testController.voltageTestPassed
                }
            }

            Column {
                spacing: parent.spacing
                anchors {
                    left: parent.left
                    right: parent.right
                }
                visible: testController.batteryPresent &&
                         (testController.hasDesignEnergyRange || testController.hasEnergyRange)

                SectionHeader {
                    //% "Energy"
                    text: qsTrId("csd-he-energy")
                }

                Label {
                    //% "Minimum: %0Wh"
                    text: qsTrId("csd-la-minimum_energy").arg(formatValue(testController.minimumEnergy, 1000000, 2))
                    visible: testController.hasEnergyRange
                }

                Label {
                    //% "Maximum: %0Wh"
                    text: qsTrId("csd-la-maximum_energy").arg(formatValue(testController.maximumEnergy, 1000000, 2))
                    visible: testController.hasEnergyRange
                }

                Label {
                    //% "Design minimum: %0Wh"
                    text: qsTrId("csd-la-design_minimum_energy").arg(formatValue(testController.minimumDesignEnergy, 1000000, 2))
                    visible: testController.hasDesignEnergyRange
                }

                Label {
                    //% "Design maximum: %0Wh"
                    text: qsTrId("csd-la-design_maximum_energy").arg(formatValue(testController.maximumDesignEnergy, 1000000, 2))
                    visible: testController.hasDesignEnergyRange
                }

                Label {
                    //% "Value: %0Wh"
                    text: qsTrId("csd-la-energy_value").arg(formatValue(testController.energyNow, 1000000, 2))
                    visible: !isNaN(testController.energyNow)
                }

                Label {
                    //% "Capacity: %0%"
                    text: qsTrId("csd-la-capacity").arg(testController.energyCapacity.toFixed(2))
                    visible: !isNaN(testController.energyCapacity)
                }

                ResultLabel {
                    result: testController.energyTestPassed
                }
            }

            Column {
                spacing: parent.spacing
                anchors {
                    left: parent.left
                    right: parent.right
                }
                visible: testController.batteryPresent &&
                         (!isNaN(testController.temperature) || testController.health !== "")

                SectionHeader {
                    //% "Health"
                    text: qsTrId("csd-he-health")
                }

                Label {
                    //% "Health: %0"
                    text: qsTrId("csd-la-health").arg(testController.health)
                    visible: testController.health !== ""
                }

                Label {
                    //% "Temperature: %0"
                    text: qsTrId("csd-la-temperature").arg(testController.temperature.toFixed(1) + "°C")
                    visible: !isNaN(testController.temperature)
                }

                ResultLabel {
                    result: testController.healthTestPassed
                }
            }
        }
    }

    function formatValue(value, divisor, fixed) {
        return (value / divisor).toFixed(2)
    }

    VerificationBatteryAutoTest {
        id: testController
        onTestFinished: {
            if (batteryPresent)
                page.setTestResult(passFail)
            page.testCompleted(false)
        }
    }
}
