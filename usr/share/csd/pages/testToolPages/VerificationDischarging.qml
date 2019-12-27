/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Csd 1.0
import ".."
import MeeGo.Connman 0.2
import MeeGo.QOfono 0.2
import com.jolla.settings.system 1.0
import org.nemomobile.systemsettings 1.0
import Nemo.KeepAlive 1.2
import Nemo.Mce 1.0

CsdTestPage {
    id: page

    property string currentModem: manager.modems.length > 0 ? manager.modems[0] : ""
    property int brightness
    property bool ambientLightSensorEnabled

    function setFlightMode(offline) {
        if (connMgr.instance.offlineMode === offline)
            return

        if (offline) {
            connMgr.instance.offlineMode = true
        } else {
            connMgr.instance.offlineMode = false
            if (!modem.powered)
                modem.powered = true
            modem.online = true
        }
    }

    SilicaListView {
        id: listView

        anchors.fill: parent
        spacing: Theme.paddingLarge
        model: !testController.chargerAttached ? testcases : null

        header: Column {
            anchors {
                left: parent.left
                leftMargin: Theme.paddingLarge
                right: parent.right
                rightMargin: Theme.paddingLarge
            }

            spacing: Theme.paddingLarge

            CsdPageHeader {
                //% "Discharging"
                title: qsTrId("csd-he-discharging")
            }

            Label {
                width: parent.width
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                height: implicitHeight + Theme.paddingMedium
                text: {
                    if (testController.chargerAttached) {
                        //% "Device is currently charging, disconnect charger to complete test."
                        return qsTrId("csd-la-device_is_currently_charging")
                    } else {
                        //% "Tests battery discharge rate under different scenarios. %0 battery state samples are collected per test at %1 second intervals. "
                        //% "Running applications may cause the test to fail due to application activity triggered by network connections being established during the test."
                        return qsTrId("csd-la-tests_battery_discharge_rate").arg(testController._SAMPLES_PER_TEST).arg(refreshTimer.interval / 1000)
                    }
                }
            }
        }

        delegate: Item {
            width: parent.width
            height: delegateColumn.height

            Column {
                id: delegateColumn

                anchors {
                    left: parent.left
                    leftMargin: Theme.paddingLarge
                    right: parent.right
                    rightMargin: Theme.paddingLarge
                }

                spacing: Theme.paddingMedium
                opacity: (testController.currentTest === index || testController.currentTest === -1) ? 1.0 : Theme.opacityLow

                Label {
                    text: {
                        if (type === "low") {
                            //% "Low power"
                            return qsTrId("csd-la-low_power")
                        } else if (type === "high") {
                            //% "High power"
                            return qsTrId("csd-la-high_power")
                        } else {
                            console.log("Warning! Power type " + type + " unlocalized")
                        }
                    }
                    color: Theme.highlightColor
                }

                Label {
                    text: {
                        if (type === "low") {
                            //% "Battery discharge test in flight mode with backlight off."
                            return qsTrId("csd-la-low_power_description")
                        } else if (type === "high") {
                            //% "Battery discharge test with all radios on and backlight brightest."
                            return qsTrId("csd-la-high_power_description")
                        } else {
                            console.log("Warning! Power type description " + type + " unlocalized")
                        }
                    }
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.Wrap
                    width: parent.width
                }

                Label {
                    width: parent.width
                    //% "Expected range: %0µA...%1µA"
                    text: qsTrId("csd-la-expected_range").arg(minimumCurrent).arg(maximumCurrent)
                }

                Label {
                    width: parent.width
                    //% "Average current: %0µA"
                    text: qsTrId("csd-la-average_current").arg(averageCurrent.toFixed(0))
                }

                Label {
                    visible: completed
                    property bool _passed: minimumCurrent <= averageCurrent && averageCurrent <= maximumCurrent
                    color: _passed ? "green" : "red"
                    text: {
                        if (_passed)
                            //% "Pass"
                            return qsTrId("csd-la-pass")
                        else if (charging)
                            //% "Failed (charging)"
                            return qsTrId("csd-la-failed_charing")
                        else
                            //% "Fail"
                            return qsTrId("csd-la-fail")
                    }
                }
            }
        }

        footer: Text {
            property double currentNow

            font.pixelSize: Theme.fontSizeLarge
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !testController.chargerAttached
            height: implicitHeight + Theme.paddingLarge
            verticalAlignment: Text.AlignVCenter

            color: {
                if (!testController.testCompleted)
                    return "white"

                if (testController.testPassed)
                    return "green"
                else
                    return "red"
            }
            text: {
                if (testController.testCompleted) {
                    if (testController.testPassed)
                        //% "All tests passed"
                        return qsTrId("csd-la-all_tests_passed")
                    else
                        //% "Tests failed"
                        return qsTrId("csd-la-tests_failed")
                } else {
                    if (isNaN(testController.currentNow))
                        //% "Initialising..."
                        return qsTrId("csd-la-initialising")
                    else
                        //% "Current: %0µA"
                        return qsTrId("csd-la-current-microampere").arg(testController.currentNow)
                }
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 3000
        repeat: true
        onTriggered: testController.recordBatteryStats()
    }

    Battery { id: battery }

    Component.onDestruction: {
        testController.stopTest()

        setFlightMode(false)
        displaySettings.ambientLightSensorEnabled = ambientLightSensorEnabled
        displaySettings.brightness = brightness
    }

    DisplayBlanking {
        id: displayBlanking
    }

    NetworkManagerFactory {
        id: connMgr
    }

    OfonoManager { id: manager }

    OfonoModem {
        id: modem
        modemPath: currentModem
    }

    DisplaySettings {
        id: displaySettings
        onPopulatedChanged: {
            // Save existing backlight settings
            page.ambientLightSensorEnabled = displaySettings.ambientLightSensorEnabled
            page.brightness = displaySettings.brightness
            // Max out the brightness before test
            displaySettings.brightness = displaySettings.maximumBrightness
            // Also disable the ambient light sensor.
            displaySettings.ambientLightSensorEnabled = false
            testController.startTest()
        }
    }

    MceChargerState {
        id: mceChargerState
    }

    Item {
        id: testController

        property int currentTest: -1
        property int settleCounter
        property bool testCompleted
        property bool testPassed
        property bool chargerAttached: mceChargerState.charging
        property double currentNow: Number.NaN

        onChargerAttachedChanged: {
            if (chargerAttached)
                stopTest()
            else
                startTest()
        }

        property int _SAMPLES_PER_TEST: 10

        property var _samples: []

        function startTest() {
            if (chargerAttached || !displaySettings.populated) {
                return
            }

            displayBlanking.preventBlanking = true
            currentTest = 0
            testCompleted = false
            testPassed = false
            currentNow = Number.NaN
            refreshTimer.start()
        }

        function stopTest() {
            currentTest = -1
            currentNow = Number.NaN
            refreshTimer.stop()

            if (!testCompleted)
                return

            var passed = true
            for (var i = 0; i < testcases.count; ++i) {
                var testData = testcases.get(i)

                if (!testData.completed) {
                    passed = false
                    break
                }

                if (testData.minimumCurrent <= testData.averageCurrent &&
                    testData.averageCurrent <= testData.maximumCurrent) {
                    passed &= true
                } else {
                    passed = false
                    break
                }
            }

            testPassed = passed
            setTestResult(passed)
            testCompleted(true)
        }

        function average(samples) {
            var sum = 0
            for (var i = 0; i < samples.length; ++i)
                sum += samples[i]

            return sum/samples.length
        }

        function recordBatteryStats() {
            if (currentTest < 0 || currentTest >= testcases.count)
                return

            if (settleCounter > 0) {
                settleCounter -= 1
                return
            }

            var sample = []
            if (currentTest < _samples.length)
                sample = _samples[currentTest]

            currentNow = battery.currentNow()
            sample[sample.length] = currentNow
            _samples[currentTest] = sample

            testcases.setProperty(currentTest, "averageCurrent", average(sample))
            testcases.setProperty(currentTest, "charging", chargerAttached)

            if (sample.length >= _SAMPLES_PER_TEST) {
                testcases.setProperty(currentTest, "completed", true)

                currentTest += 1
            }
        }

        onCurrentTestChanged: {
            if (currentTest < 0)
                return

            if (currentTest >= testcases.count) {
                testCompleted = true
                stopTest()
                return
            }

            settleCounter = 4
            currentNow = Number.NaN
            listView.positionViewAtIndex(currentTest, ListView.Contain)
            var testData = testcases.get(currentTest)

            setFlightMode(testData.flightMode)
            displaySettings.ambientLightSensorEnabled = testData.ambientLightSensorEnabled
            displaySettings.brightness = testData.brightness
        }

        ListModel {
            id: testcases

            ListElement {
                type: "low"

                flightMode: true
                ambientLightSensorEnabled: false
                brightness: 0

                // Expected current range (µA)
                minimumCurrent: 0
                maximumCurrent: 485000

                averageCurrent: 0
                charging: false

                completed: false
            }
            ListElement {
                type: "high"

                flightMode: false
                ambientLightSensorEnabled: false
                brightness: 100

                // Expected current range (µA)
                minimumCurrent: 0
                maximumCurrent: 800000

                averageCurrent: 0
                charging: false

                completed: false
            }
        }
    }
}
