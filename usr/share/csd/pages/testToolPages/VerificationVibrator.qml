/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.2
import Sailfish.Silica 1.0
import ".."

CsdTestPage {
    id: page

    CsdPageHeader {
        id: title
        //% "Vibrator"
        title: qsTrId("csd-he-vibrator")
    }

    Timer {
        interval: 1000
        repeat: true
        running: page.status === PageStatus.Active
        onTriggered: testVibrator.running = !testVibrator.running
    }

    Vibrator {
        id: testVibrator
    }

    Label {
        id: question
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSizeLarge
        //% "Does device vibrate?"
        text: qsTrId("csd-la-does_device_vibrate")
    }

    ButtonLayout {
        anchors {
            top: question.bottom
            topMargin: Theme.paddingLarge
            horizontalCenter: parent.horizontalCenter
        }
        rowSpacing: Theme.paddingLarge*3

        PassButton {
            id: passButton
            onClicked: {
                testVibrator.stop()
                setTestResult(true)
                testCompleted(true)
            }
        }
        FailButton {
            onClicked: {
                testVibrator.stop()
                setTestResult(false)
                testCompleted(true)
            }
        }
    }
}
