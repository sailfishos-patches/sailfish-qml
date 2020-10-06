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
            //% "Headset detection"
            title: qsTrId("csd-he-headset_detection")
        }
        DescriptionItem {
            visible: !page.started && !page.failed
            //% "1. Make sure you have headset device (headset has microphone).<br>2. After pressing Start, follow on screen instructions. If on screen instructions do not change when plugging the headset, press Fail."
            text: qsTrId("csd-la-verification_headset_detect_description")
        }
    }

    Label {
        id: resultPass

        visible: page.done
        anchors.centerIn: parent
        color: "green"
        wrapMode: Text.Wrap
        width: parent.width-(2*Theme.paddingLarge)
        font.pixelSize: Theme.fontSizeLarge
        //% "Headset detection test passed!"
        text: qsTrId("csd-la-headset_detection_test_passed")
    }

    Label {
        visible: page.started && !page.done
        anchors.centerIn: parent
        color: "green"
        wrapMode: Text.Wrap
        width: parent.width-(2*Theme.paddingLarge)
        font.pixelSize: Theme.fontSizeLarge
        text: detect.wiredOutputConnected ? //% "Disconnect headset plug from device"
                                            qsTrId("csd-la-headset_detection_disconnect_headset")
                                          : //% "Connect headset plug to device"
                                            qsTrId("csd-la-headset_detection_connect_headset")
    }

    Timer {
        interval: 2000
        running: resultPass.visible
        repeat: false
        onTriggered: testCompleted(true)
    }

    Label {
        visible: page.failed
        anchors.centerIn: parent
        color: "red"
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSizeLarge
        width: parent.width-(2*Theme.paddingLarge)
        //% "Headset detection test failed!"
        text: qsTrId("csd-la-headset_detection_test_failed")
    }

    AudioRoute {
        id: detect
        property int count
        property int succeedCount: 2

        function testRound() {
            count++
            if (count >= succeedCount) {
                setTestResult(true)
                page.done = true
                testCompleted(false)
            }

        }

        onWiredOutputConnectedChanged: {
            if (page.started) {
                testRound()
            } else if (wiredOutputConnected) {
                // If headset is already connected let's do one more
                // round so we end up with headset disconnected.
                count = -1
            }
        }
    }

    BottomButton {
        //% "Start"
        text: qsTrId("csd-la-start")
        visible: !page.started && !page.failed
        onClicked: {
            page.started = true
        }
    }

    FailBottomButton {
        visible: !page.done && page.started
        onClicked: {
            setTestResult(false)
            testCompleted(true)
        }
    }
}
