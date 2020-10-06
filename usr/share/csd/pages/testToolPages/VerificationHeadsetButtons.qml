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

    property bool started
    property bool failed
    property bool done

    Column {
        width: parent.width
        spacing: Theme.paddingLarge
        CsdPageHeader {
            //% "Headset buttons"
            title: qsTrId("csd-he-headset_buttons")
        }
        DescriptionItem {
            visible: !page.started && !page.failed
            //% "1. Make sure you have headset device with button(s) plugged in.<br>2. After pressing Start, follow on screen instructions. "
            //% "If on screen instructions do not change when operating the headset buttons, press Fail."
            text: qsTrId("csd-la-verification_headset_buttons_description")
        }
    }

    Label {
        visible: page.done && !detect.pressed
        anchors.centerIn: parent
        color: "green"
        wrapMode: Text.Wrap
        width: parent.width-(2*Theme.paddingLarge)
        font.pixelSize: Theme.fontSizeLarge
        //% "Headset buttons test passed!"
        text: qsTrId("csd-la-headset_buttons_test_passed")
    }

    Label {
        id: displayPressButton

        visible: page.started && !holdTimer.completed
        anchors.centerIn: parent
        wrapMode: Text.Wrap
        width: parent.width-(2*Theme.paddingLarge)
        font.pixelSize: Theme.fontSizeLarge
        //% "Press and hold headset button"
        text: qsTrId("csd-la-headset_buttons_press_and_hold")
    }

    Label {
        visible: holdTimer.completed && detect.pressed
        anchors.centerIn: parent
        wrapMode: Text.Wrap
        width: parent.width-(2*Theme.paddingLarge)
        font.pixelSize: Theme.fontSizeLarge
        //% "Release headset button"
        text: qsTrId("csd-la-headset_buttons_release")
    }

    ProgressBar {
        visible: holdTimer.running
        anchors.top: displayPressButton.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width-(2*Theme.paddingLarge)
        value: holdTimer.count / holdTimer.rounds
    }

    Timer {
        id: holdTimer

        interval: 50    // Hold timer total time 2 seconds.
        repeat: true
        property int count
        property int rounds: 40
        property bool completed

        onTriggered: {
            if (count == rounds) {
                stop()
                completed = true
            }
            count++
        }

        function startHold() {
            count = 0
            restart()
        }

        function stopHold() {
            stop()
        }
    }

    Label {
        visible: page.failed
        anchors.centerIn: parent
        color: "red"
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSizeLarge
        width: parent.width-(2*Theme.paddingLarge)
        //% "Headset buttons test failed!"
        text: qsTrId("csd-la-headset_buttons_test_failed")
    }

    HeadsetDetect {
        id: detect

        property bool pressed

        onButtonsPressedChanged: {
            pressed = buttonPressed(HeadsetDetect.ButtonMisc | HeadsetDetect.KeyMedia | HeadsetDetect.KeyPlayPause)

            if (holdTimer.completed) {
                setTestResult(true)
                page.done = true
                testCompleted(false)
            } else {
                if (pressed) {
                    holdTimer.startHold()
                } else {
                    holdTimer.stopHold()
                }
            }
        }
    }

    BottomButton {
        visible: !page.started && !page.failed
        //% "Start"
        text: qsTrId("csd-la-start")
        onClicked: {
            detect.openDevice()
            detect.openButtonDevice()

            if (!detect.buttonsFound()) {
                page.failed = true
                setTestResult(false)
                testCompleted(false)
            } else {
                page.started = true
            }
        }
    }

    FailBottomButton {
        visible: page.started && !page.done
        onClicked: {
            setTestResult(false)
            testCompleted(true)
        }
    }

    Timer {
        interval: 2000
        running: page.done || page.failed
        onTriggered: testCompleted(true)
    }
}
