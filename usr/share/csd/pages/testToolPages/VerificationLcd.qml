/*
 * Copyright (c) 2016 - 2022 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

CsdTestPage {
    id: page

    readonly property var testData: [
        //% "Showing: Color gradient"
        [qsTrId("csd-la-lcd_show_gradient"), "black"],
        //% "Showing: Black"
        [qsTrId("csd-la-lcd_show_black"), "black"],
        //% "Showing: White"
        [qsTrId("csd-la-lcd_show_white"), "white"],
        //% "Showing: Red"
        [qsTrId("csd-la-lcd_show_red"), "red"],
        //% "Showing: Green"
        [qsTrId("csd-la-lcd_show_green"), "green"],
        //% "Showing: Blue"
        [qsTrId("csd-la-lcd_show_blue"), "blue"],
        // Sentinel
        ["", Theme.overlayBackgroundColor]]
    property int testCase
    readonly property string testLabel: testData[testCase][0]
    readonly property string testColor: testData[testCase][1]
    readonly property bool testEnded: testLabel == ""
    readonly property string textColor: testColor == "white" ? "black" : "yellow"

    function progressTest() {
        testCase++
    }

    Image {
        id: image
        visible: testCase == 0
        anchors.fill: parent
        source: "/usr/share/csd/testdata/lcdtest.png"
    }

    Rectangle {
        id: rect
        color: testColor

        anchors.fill: parent
        visible: !image.visible

        Label {
            id: buttonText
            anchors.centerIn: parent
            width: parent.width - (Theme.paddingLarge * 2)
            wrapMode: Text.Wrap
            visible: testEnded
            font.pixelSize: Theme.fontSizeLarge

            //% "Does it show RGB?"
            text: qsTrId("csd-la-show_rgb")
        }

        ButtonLayout {
            id: buttonRow
            visible: testEnded

            anchors {
                top: buttonText.bottom
                topMargin: Theme.paddingLarge
                horizontalCenter: parent.horizontalCenter
            }
            rowSpacing: Theme.paddingMedium

            PassButton {
                onClicked: {
                    setTestResult(true)
                    testCompleted(true)
                }
            }
            FailButton {
                onClicked: {
                    setTestResult(false)
                    testCompleted(true)
                }
            }
        }
    }

    Label {
        id: showingColorLabel
        color: textColor
        visible: !buttonRow.visible
        anchors {
            left: tapToProceedLabel.left
            bottom: tapToProceedLabel.top
        }
        text: testLabel
    }

    Label {
        id: tapToProceedLabel
        color: textColor
        visible: showingColorLabel.visible
        anchors {
            left: parent.left
            leftMargin: Theme.paddingLarge
            bottom: parent.bottom
            bottomMargin: Theme.paddingLarge
        }
        //% "Tap screen to proceed"
        text: qsTrId("csd-la-lcd_tap_to_proceed")
    }

    MouseArea {
        id: ma

        anchors.fill: parent
        onClicked: progressTest()
        enabled: !testEnded
    }

    Timer {
        interval: 750
        repeat: true
        running: page.runInTests
        onTriggered: {
            if (buttonRow.visible) {
                setTestResult(true)
                testCompleted(true)
            } else {
                progressTest()
            }
        }
    }
}
