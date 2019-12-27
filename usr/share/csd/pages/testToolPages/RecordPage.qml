/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0
import Csd 1.0
import ".."

CsdTestPage {
    id: page

    property alias volume: recorder.volume
    property alias category: recorder.category
    property alias inputSource: recorder.inputSource
    property alias csdMode: recorder.csdMode

    property alias title: header.title

    //% "1. Make sure headset is not connected.<br>2. Press 'Record' to speak above microphone."
    property string recordHint: qsTrId("csd-la-audio_record_description")
    //% "Press 'Stop' to stop recording."
    property string stopHint: qsTrId("csd-la-verification_audio_record_stop_description")
    //% "Press 'Play' to check voice from Loudspeaker."
    property string playbackHint: qsTrId("csd-la-verification_audio_record_play_description")

    property bool wired

    signal recordStopped

    state: "initial"

    states: [
        State {
            name: "initial"
        },
        State {
            name: "record"
        },
        State {
            name: "playback"
        },
        State {
            name: "done"
        }
    ]

    Recorder {
        id: recorder

        volume: 1.0
    }

    Column {
        width: parent.width
        spacing: Theme.paddingLarge

        CsdPageHeader {
            id: header
        }

        DescriptionItem {
            text: {
                switch (page.state) {
                case "initial":
                    return page.recordHint
                case "record":
                    return page.stopHint
                case "playback":
                    return page.playbackHint
                default:
                    return ""
                }
            }
        }
    }

    AudioRoute {
        id: route
    }

    BottomButton {
        visible: page.state != "done"
        enabled: wired == route.wiredInputConnected
        text: {
            switch (page.state) {
            case "initial":
                //% "Record"
                return qsTrId("csd-la-record")
            case "record":
                //% "Stop"
                return qsTrId("csd-la-stop")
            case "playback":
                //% "Play"
                return qsTrId("csd-la-play")
            default:
                return ""
            }
        }
        onClicked: {
            if (page.state == "initial") {
                recorder.record()
                page.state = "record"
            } else if (page.state == "record") {
                recorder.stopRecord()
                page.recordStopped()
                page.state = "playback"
            } else if (page.state == "playback") {
                recorder.play()
                page.state = "done"
            }
        }
    }

    Label {
        id: resultLabel

        visible: page.state == "done"
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSizeLarge
        //% "Verification result"
        text: qsTrId("csd-la-verification_result")
    }

    ButtonLayout {
        visible: page.state == "done"
        anchors {
            top: resultLabel.bottom
            topMargin: Theme.paddingLarge
            horizontalCenter: parent.horizontalCenter
        }
        rowSpacing: Theme.paddingLarge*3

        PassButton {
            onClicked: {
                recorder.stop()
                setTestResult(true)
                testCompleted(true)
            }
        }
        FailButton {
            onClicked: {
                recorder.stop()
                setTestResult(false)
                testCompleted(true)
            }
        }
    }
}
