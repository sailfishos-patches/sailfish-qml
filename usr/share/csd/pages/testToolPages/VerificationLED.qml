/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.dbus 2.0
import Csd 1.0
import ".."

CsdTestPage {
    id: page

    CsdPageHeader {
        id: title
        //% "LED"
        title: qsTrId("csd-he-led")
    }

    Label {
        id: question
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSizeLarge
        text: testController.currentDisplayInstructions
    }

    ButtonLayout {
        anchors {
            top: question.bottom
            topMargin: Theme.paddingLarge
            horizontalCenter: parent.horizontalCenter
        }
        rowSpacing: Theme.paddingLarge*3

        PassButton {
            onClicked: testController.setCurrentTestResult(true)
        }
        FailButton {
            onClicked: testController.setCurrentTestResult(false)
        }
    }

    Component.onCompleted: {
        switch (CsdHwSettings.ledType) {
        case "Binary":
            // If there is only single color LED let's not care
            // about the color to simplify things
            testcases.append({"pattern":"PatternCsdLedBlink"})
            break;
        case "White":
            testcases.append({"pattern":"PatternCsdWhiteSolid"})
            testcases.append({"pattern":"PatternCsdWhiteBlink"})
            break;
        case "AmberGreen":
            testcases.append({"pattern":"PatternCsdYellowSolid"})
            testcases.append({"pattern":"PatternCsdGreenSolid"})
            testcases.append({"pattern":"PatternCsdLedBlink"})
            break;
        case "RedGreen":
            testcases.append({"pattern":"PatternCsdRedSolid"})
            testcases.append({"pattern":"PatternCsdGreenSolid"})
            testcases.append({"pattern":"PatternCsdLedBlink"})
            break;
        default: // RGB
            testcases.append({"pattern":"PatternCsdWhiteBlink"})
            testcases.append({"pattern":"PatternCsdRedSolid"})
            testcases.append({"pattern":"PatternCsdGreenSolid"})
            testcases.append({"pattern":"PatternCsdBlueSolid"})
            break;
        }

        // The csd led patterns are configured so that they
        // can be activated even if led feature is disabled.
        //
        // Disable normal led patterns, so that they do not
        // get activated while we expect to see only CSD
        // controlled led patterns.
        mce.call("req_led_disable", "")
        testController.startTest()
    }

    Component.onDestruction: {
        mce.ledOn = false
        // Re-enable normal led patterns
        mce.call("req_led_enable", "")
    }

    DBusInterface {
        id: mce

        property bool ledOn
        property string pattern

        service: "com.nokia.mce"
        iface: "com.nokia.mce.request"
        path: "/com/nokia/mce/request"
        bus: DBus.SystemBus

        onLedOnChanged: {
            if (ledOn)
                mce.call("req_led_pattern_activate", pattern)
            else
                mce.call("req_led_pattern_deactivate", pattern)
        }
    }

    Item {
        id: testController

        property int currentTest: -1

        property string currentDisplayInstructions: {
            if (currentTest < 0 || currentTest >= testcases.count)
                return ""

            var testData = testcases.get(currentTest)
            return testcases.displayInstructions(testData.pattern)
        }

        function startTest() {
            currentTest = 0
        }

        function stopTest() {
            if (currentTest >= testcases.count) {
                // Set overall test result if all test cases have been completed
                var passed = true
                for (var i = 0; i < testcases.count && passed; ++i) {
                    var testData = testcases.get(i)
                    passed &= testData.passed
                }

                setTestResult(passed)
                testCompleted(true)
            }

            currentTest = -1
        }

        function setCurrentTestResult(result) {
            testcases.setProperty(currentTest, "passed", result)
            currentTest += 1
        }

        onCurrentTestChanged: {
            if (currentTest < 0)
                return

            if (currentTest >= testcases.count) {
                stopTest()
                return
            }

            var testData = testcases.get(currentTest)

            mce.ledOn = false
            mce.pattern = testData.pattern
            mce.ledOn = true
        }

        ListModel {
            id: testcases

            function displayInstructions(pattern) {
                switch (pattern) {
                case "PatternCsdLedBlink":
                    //% "Is LED blinking?"
                    return qsTrId("csd-la-is_led_blinking")
                case "PatternCsdWhiteBlink":
                    //% "Is white LED blinking?"
                    return qsTrId("csd-la-is_white_led_blinking")
                case "PatternCsdRedSolid":
                    //% "Is red LED on?"
                    return qsTrId("csd-la-is_red_led_on")
                case "PatternCsdGreenSolid":
                    //% "Is green LED on?"
                    return qsTrId("csd-la-is_green_led_on")
                case "PatternCsdBlueSolid":
                    //% "Is blue LED on?"
                    return qsTrId("csd-la-is_blue_led_on")
                case "PatternCsdYellowSolid":
                    //% "Is yellow LED on?"
                    return qsTrId("csd-la-is_yellow_led_on")
                case "PatternCsdWhiteSolid":
                    //% "Is white LED on?"
                    return qsTrId("csd-la-is_white_led_on")
                default:
                    return ""
                }
            }
        }
    }
}

