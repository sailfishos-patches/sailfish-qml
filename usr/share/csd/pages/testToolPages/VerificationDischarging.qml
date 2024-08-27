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
import Connman 0.2
import QOfono 0.2
import com.jolla.settings.system 1.0
import org.nemomobile.systemsettings 1.0
import Nemo.KeepAlive 1.2
import Nemo.Mce 1.0

CsdTestPage {
    id: page

    property string currentModem: manager.modems.length > 0 ? manager.modems[0] : ""
    property int savedBrightness
    property bool savedAmbientLightSensorEnabled
    property bool savedOfflineMode
    property bool settingsSaved
    property bool blockedByCharger: testController.chargerAttached && !testController.testFinished && !testController.testRunning

    function applyTestingSettings() {
        if (!settingsSaved) {
            savedAmbientLightSensorEnabled = displaySettings.ambientLightSensorEnabled
            savedBrightness = displaySettings.brightness
            savedOfflineMode = connMgr.instance.offlineMode
            settingsSaved = true
        }

        displaySettings.ambientLightSensorEnabled = false
        displayBlanking.preventBlanking = true
    }

    function restoreOriginalSettings() {
        if (settingsSaved) {
            displaySettings.ambientLightSensorEnabled = savedAmbientLightSensorEnabled
            displaySettings.brightness = savedBrightness
            setFlightMode(savedOfflineMode)
        }

        displayBlanking.preventBlanking = false
    }

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
        model: page.blockedByCharger ? null : testcases

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
                    if (page.blockedByCharger) {
                        //% "Device is currently charging, disconnect charger to complete test."
                        return qsTrId("csd-la-device_is_currently_charging")
                    } else {
                        //% "Tests battery discharge rate under different scenarios. %0 battery state samples are collected per test at %1 second intervals. "
                        //% "Running applications may cause the test to fail due to application activity triggered by network connections being established during the test."
                        return qsTrId("csd-la-tests_battery_discharge_rate").arg(testController._SAMPLES_TO_CAPTURE).arg(testController._SAMPLE_TIME / 1000)
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
                    property bool currentDirectionFailure: positiveCurrentSeen && negativeCurrentSeen
                    property bool currentLimitFailure: averageCurrent < minimumCurrent || averageCurrent > maximumCurrent
                    property bool testSuccessfullyCompleted: completed && !currentDirectionFailure && !currentLimitFailure

                    visible: completed
                    color: testSuccessfullyCompleted ? "green" : "red"
                    text: {
                        if (testSuccessfullyCompleted)
                            //% "Pass"
                            return qsTrId("csd-la-pass")
                        else if (currentDirectionFailure)
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
            font.pixelSize: Theme.fontSizeLarge
            anchors.horizontalCenter: parent.horizontalCenter
            visible: testController.testRunning || testController.testFinished
            height: implicitHeight + Theme.paddingLarge
            verticalAlignment: Text.AlignVCenter

            color: {
                if (!testController.testFinished)
                    return "white"

                if (testController.testPassed)
                    return "green"
                else
                    return "red"
            }
            text: {
                if (testController.testFinished) {
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
        interval: testController._SAMPLE_TIME
        repeat: true
        running: testController.testRunning
        onTriggered: testController.recordBatteryStats()
    }

    Battery { id: battery }

    Connections {
        target: Qt.application
        onAboutToQuit: testController.stopTest()
    }

    Component.onDestruction: {
        testController.stopTest()
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
        onPopulatedChanged: testController.startTest()
    }

    MceChargerState {
        id: mceChargerState
        onValidChanged: testController.startTest()
    }

    Item {
        id: testController

        property bool testPassed
        property bool testFinished
        property bool testStopped
        property bool testStarted
        property bool testRunning: testStarted && !testStopped
        property double currentNow: Number.NaN
        property int currentTest: -1
        readonly property int _SAMPLE_TIME: 2000
        readonly property int _SAMPLES_TO_IGNORE: 30 // e.g. L500D needs >50s settle time
        readonly property int _SAMPLES_TO_CAPTURE: 15
        property var sampleData: null
        property int settleCounter
        property bool chargerAttached: mceChargerState.charging

        function startTest() {
            if (!displaySettings.populated || !mceChargerState.valid)
                return

            if (testFinished || (testStarted && !testStopped) || chargerAttached)
                return

            applyTestingSettings()

            testPassed = false
            testFinished = false
            testStopped = false
            testStarted = true
            currentNow = Number.NaN
            currentTest = 0
        }

        function stopTest() {
            if (testStopped || !testStarted)
                return

            testStopped = true
            currentTest = -1
            currentNow = Number.NaN

            restoreOriginalSettings()
        }

        function finishTest() {
            stopTest()

            if (testFinished)
                return

            testFinished = true

            var passed = true
            for (var i = 0; passed && i < testcases.count; ++i) {
                var testData = testcases.get(i)
                if (!testSuccessfullyCompleted(testData))
                    passed = false
            }

            testPassed = passed
            setTestResult(passed)
            testCompleted(false)
        }

        function average(samples) {
            var sum = 0
            for (var i = 0; i < samples.length; ++i)
                sum += samples[i]

            return sum/samples.length
        }

        function currentDirectionFailure(testData) {
            return testData.negativeCurrentSeen && testData.positiveCurrentSeen
        }

        function currentLimitFailure(testData) {
            return testData.averageCurrent < testData.minimumCurrent || testData.averageCurrent > testData.maximumCurrent
        }

        function testSuccessfullyCompleted(testData) {
            return testData.completed && !currentDirectionFailure(testData) && !currentLimitFailure(testData)
        }

        function recordBatteryStats() {
            if (currentTest < 0 || currentTest >= testcases.count)
                return

            if (settleCounter > 0) {
                settleCounter -= 1
                return
            }

            // Note: Current sign got flipped at Android base 10
            // Normalize to "discharging is positive" expected by CSD
            // Fail test if current sign changes during measurement
            currentNow = battery.currentNow()
            if (currentNow < 0) {
                testcases.setProperty(currentTest, "negativeCurrentSeen", true)
                currentNow = -currentNow
            } else if (currentNow > 0) {
                testcases.setProperty(currentTest, "positiveCurrentSeen", true)
            }

            sampleData[sampleData.length] = currentNow

            testcases.setProperty(currentTest, "averageCurrent", average(sampleData))

            if (sampleData.length >= _SAMPLES_TO_CAPTURE) {
                testcases.setProperty(currentTest, "completed", true)
                currentTest += 1
            }
        }

        onChargerAttachedChanged: {
            if (chargerAttached)
                stopTest()
            else
                startTest()
        }

        onCurrentTestChanged: {
            if (currentTest < 0)
                return

            if (currentTest >= testcases.count) {
                finishTest()
                return
            }

            testcases.setProperty(currentTest, "completed", false)
            testcases.setProperty(currentTest, "averageCurrent", 0)
            testcases.setProperty(currentTest, "positiveCurrentSeen", false)
            testcases.setProperty(currentTest, "negativeCurrentSeen", false)

            sampleData = []
            settleCounter = _SAMPLES_TO_IGNORE
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
                type: "high"

                flightMode: false
                ambientLightSensorEnabled: false
                brightness: 100

                // Expected current range (µA)
                minimumCurrent: 0
                maximumCurrent: 800000

                averageCurrent: 0
                positiveCurrentSeen: false
                negativeCurrentSeen: false
                completed: false
            }
            ListElement {
                type: "low"

                flightMode: true
                ambientLightSensorEnabled: false
                brightness: 0

                // Expected current range (µA)
                minimumCurrent: 0
                maximumCurrent: 485000

                averageCurrent: 0
                positiveCurrentSeen: false
                negativeCurrentSeen: false
                completed: false
            }
        }
    }
}
