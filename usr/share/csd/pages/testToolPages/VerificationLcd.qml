/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

CsdTestPage {
    id: page

    property int testCase

    function progressTest() {
        testCase++

        rect.visible = true

        switch (testCase) {
        case 1:
            rect.color = "white"
            break
        case 2:
            rect.color = "black"
            break
        case 3:
            rect.color = "red"
            break
        case 4:
            rect.color = "green"
            break
        case 5:
            rect.color = "blue"
            break
        default:
            rect.color = Theme.overlayBackgroundColor
            buttonText.visible = true
            buttonRow.visible = true
            ma.enabled = false
            break
        }
    }

    Image {
        anchors.fill: parent
        source: "/usr/share/csd/testdata/lcdtest.png"
    }

    Rectangle {
        id: rect
        color: "white"

        anchors.fill: parent
        visible: false

        Label {
            id: buttonText
            anchors.centerIn: parent
            width: parent.width - (Theme.paddingLarge * 2)
            wrapMode: Text.Wrap
            visible: false
            font.pixelSize: Theme.fontSizeLarge

            //% "Does it show RGB?"
            text: qsTrId("csd-la-show_rgb")
        }

        ButtonLayout {
            id: buttonRow
            visible: false

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

    MouseArea {
        id: ma

        anchors.fill: parent
        onClicked: progressTest()
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
