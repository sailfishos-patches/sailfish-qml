/*
 * Copyright (c) 2014 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Csd 1.0
import org.nemomobile.systemsettings 1.0
import Nemo.KeepAlive 1.2
import ".."

CsdTestPage {
    id: page

    Column {
        width: parent.width
        CsdPageHeader {
            //% "Battery Resistance"
            title: qsTrId("csd-he-battery_resistance")
        }

        SectionHeader {
            //% "Short time test"
            text: qsTrId("csd-he-short_time_test")
        }

        Label {
            wrapMode: Text.Wrap
            x: Theme.paddingLarge
            width: parent.width - 2* Theme.paddingLarge
            color: Theme.highlightColor
            //% "Tests the internal resistance of the battery. Takes %0 samples."
            text: qsTrId("csd-la-tests_battery_resistance").arg(testController._SHORT_TEST_SAMPLES)
        }

        Item {
            width: parent.width; height: Theme.paddingMedium
        }

        Label {
            //% "Samples: %0"
            text: qsTrId("csd-la-samples").arg(testController.samples)
            x: Theme.paddingLarge
        }
        Label {
            text: "β: " + (!isNaN(testController.beta) ? testController.beta.toFixed(3) : "0.000")
            x: Theme.paddingLarge
        }
        Label {
            text: "α: " + (!isNaN(testController.alpha) ? testController.alpha.toFixed(3) : "0.000")
            x: Theme.paddingLarge
        }
        Label {
            text: "σ²: " + (!isNaN(testController.rsq) ? testController.rsq.toFixed(3) : "0.000")
            x: Theme.paddingLarge
        }

        Item {
            width: parent.width; height: Theme.paddingMedium
        }

        Label {
            //% "Pass criteria"
            text: qsTrId("csd-la-pass_criteria")
            color: Theme.highlightColor
            x: Theme.paddingLarge
        }

        Item {
            width: parent.width; height: Theme.paddingMedium
        }

        Label {
            text: "β > -0.3, σ² > 0.85"
            x: Theme.paddingLarge
        }

        Item {
            width: parent.width; height: Theme.paddingMedium
        }

        Label {
            x: Theme.paddingLarge
            font.pixelSize: Theme.fontSizeLarge
            visible: !testController.testing
            //% "Pass"
            text: testController.shortTimeTestPassed ? qsTrId("csd-la-pass")
                                                       //% "Fail"
                                                     : qsTrId("csd-la-fail")
            color: testController.shortTimeTestPassed ? "green" : "red"
        }
    }

    Component.onDestruction: testController.stopTest()

    Timer {
        id: sampleTimer
        interval: 5000
        repeat: true
        onTriggered: testController.sampleBattery()
    }

    Battery { id: battery }

    DisplaySettings {
        id: displaySettings
        onPopulatedChanged: {
            // Save existing backlight settings
            testController.ambient = displaySettings.ambientLightSensorEnabled
            testController.brightness = displaySettings.brightness
            displaySettings.brightness = 0
            // Also disable the ambient light sensor.
            displaySettings.ambientLightSensorEnabled = false
            testController.startTest()
        }
    }

    DisplayBlanking {
        preventBlanking: testController.testing
    }

    Item {
        id: testController

        property int brightness
        property bool ambient

        property bool testing
        property bool shortTimeTestPassed

        // calculated stats
        property double sx
        property double sy
        property double sxx
        property double sxy
        property double syy

        property int samples

        property double beta
        property double alpha
        property double rsq

        property int _SHORT_TEST_SAMPLES: 30

        function startTest() {
            if (!displaySettings.populated)
                return

            testing = true

            // Setup test
            battery.disableCharger()

            sx = 0
            sy = 0
            sxx = 0
            sxy = 0
            syy = 0

            samples = 0

            beta = 0
            alpha = 0
            rsq = 0

            sampleTimer.start()
        }

        function stopTest() {
            if (!testing)
                return

            sampleTimer.stop()

            displaySettings.brightness = testController.brightness
            displaySettings.ambientLightSensorEnabled = testController.ambient

            battery.enableCharger()

            if (samples >= _SHORT_TEST_SAMPLES) {
                shortTimeTestPassed = beta > -0.3 && rsq > 0.85
                setTestResult(shortTimeTestPassed)
                testCompleted(false)
            }

            testing = false
        }

        function sampleBattery() {
            var v = battery.voltageNow() / 1000000
            var i = battery.currentNow() / 1000000
            samples += 1

            sx += i
            sy += v
            sxx += i*i
            sxy += i*v
            syy += v*v

            var n = samples

            beta = (n * sxy - sx * sy) / (n * sxx - sx * sx)
            alpha = (sy - beta * sx) / n
            var _r = (n * sxy - sx * sy) / Math.sqrt((n * sxx - sx * sx) * (n * syy - sy * sy))
            rsq = _r*_r

            displaySettings.brightness = 100 - displaySettings.brightness

            if (samples >= _SHORT_TEST_SAMPLES)
                stopTest()
        }
    }
}
