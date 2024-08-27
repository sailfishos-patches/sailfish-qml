/*
 * Copyright (c) 2017 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0
import Csd 1.0
import ".."

CsdTestPage {
    id: page

    CsdPageHeader {
        id: title
        //% "Button Backlight"
        title: qsTrId("csd-he-button-backlight")
    }

    Label {
        id: question
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSizeLarge
        text: testController.currentDisplayInstructions
    }

    ButtonLayout {
        id: buttonLayout
        anchors {
            top: question.bottom
            topMargin: Theme.paddingLarge
            horizontalCenter: parent.horizontalCenter
        }
        rowSpacing: Theme.paddingLarge*3

        PassButton {
            id: passButton
            onClicked: testController.setCurrentTestResult(true)
        }
        FailButton {
            onClicked: testController.setCurrentTestResult(false)
        }
    }

    Text {
        anchors {
            top: buttonLayout.bottom
            topMargin: Theme.paddingLarge
            horizontalCenter: parent.horizontalCenter
        }
        font.pixelSize: Theme.fontSizeLarge
        color: "red"
        visible: !passButton.enabled
        //% "Backlight control failure"
        text: qsTrId("csd-he-button-backlight-control-failure")
    }

    Component.onCompleted: {
        testcases.append({"name":"BacklightBlinking"})

        // Make sure that we do not have dangling backlight enable
        // left in place and fetch overall backlight state from mce
        backlightControl.call("req_button_backlight_mode",
                              backlightControl.enable
                              ? MceButtonBacklight.ForceOn
                              : MceButtonBacklight.ForceOff)
        backlightControl.call("get_button_backlight", [], function(enabled) {
            backlightStatus.active = enabled
        })

        testController.startTest()
    }

    Component.onDestruction: {
        // Do not leave the backlight enabled
        backlightControl.call("req_button_backlight_mode",
                              MceButtonBacklight.Policy)
    }

    DBusInterface {
        id: backlightControl
        bus: DBus.SystemBus
        service: "com.nokia.mce"
        path: "/com/nokia/mce/request"
        iface: "com.nokia.mce.request"

        property bool enable

        onEnableChanged: {
            backlightControl.call("req_button_backlight_mode",
                                  enable
                                  ? MceButtonBacklight.ForceOn
                                  : MceButtonBacklight.ForceOff)
        }
    }

    DBusInterface {
        id: backlightStatus
        bus: DBus.SystemBus
        service: "com.nokia.mce"
        path: "/com/nokia/mce/signal"
        iface: "com.nokia.mce.signal"
        signalsEnabled: true

        property bool active

        function sig_button_backlight_ind(enabled) {
            active = enabled
        }
    }

    Item {
        id: testController

        property int currentTest: -1
        property bool inSync: backlightControl.enable == backlightStatus.active

        property string currentDisplayInstructions: {
            if (currentTest < 0 || currentTest >= testcases.count)
                return ""

            var testData = testcases.get(currentTest)
            return testcases.displayInstructions(testData.name)
        }

        function evaluateTestState() {
            if (currentTest < 0) {
                testFailureTimer.stop()
                controlFailureTimer.stop()
                backlightToggleTimer.stop()
            } else if (testController.inSync) {
                passButton.enabled = true
                testFailureTimer.stop()
                controlFailureTimer.stop()
                backlightToggleTimer.start()
            } else {
                testFailureTimer.start()
                controlFailureTimer.start()
                backlightToggleTimer.stop()
            }
        }

        function startTest() {
            currentTest = 0
        }

        function stopTest() {
            var passed = (currentTest >= testcases.count)
            for (var i = 0; passed && i < testcases.count; ++i) {
                    var testData = testcases.get(i)
                    passed &= testData.passed
            }
            currentTest = -1
            setTestResult(passed)
            testCompleted(true)
        }

        function setCurrentTestResult(result) {
            testcases.setProperty(currentTest, "passed", result)
            currentTest += 1
        }

        onInSyncChanged: {
            evaluateTestState()
        }

        onCurrentTestChanged: {
            evaluateTestState()

            if (currentTest >= testcases.count) {
                stopTest()
            }
        }

        ListModel {
            id: testcases

            function displayInstructions(name) {
                switch (name) {
                case "BacklightBlinking":
                    //% "Is button backlight blinking?"
                    return qsTrId("csd-la-button-backlight-off")
                default:
                    return ""
                }
            }
        }
    }

    Timer {
        id: testFailureTimer
        interval: 5000
        onTriggered: testController.stopTest()
    }

    Timer {
        id: controlFailureTimer
        interval: 500
        onTriggered: passButton.enabled = false
    }

    Timer {
        id: backlightToggleTimer
        interval: 500
        onTriggered: backlightControl.enable = !backlightControl.enable
    }
}
