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

    property bool _testing

    function startTest() {
        _testing = true
        playMusic.play()
    }

    BottomButton {
        id: startButton

        visible: !runInTests && !_testing
        enabled: !route.wiredOutputConnected

        //% "Start"
        text: qsTrId("csd-la-start")
        onClicked: startTest()
    }

    Column {
        width: parent.width
        spacing: Theme.paddingLarge
        CsdPageHeader {
            //% "Loudspeaker playback"
            title: qsTrId("csd-he-loudspeaker_playback")
        }

        DescriptionItem {
            visible: !_testing
            text: runInTests ? //% "1. Make sure headset is not connected."
                               qsTrId("csd-la-audio_play_music_loudspeaker_runin_description")
                             : //% "1. Make sure headset is not connected.<br>2. Press 'Start' button."
                               qsTrId("csd-la-audio_play_music_loudspeaker_description")
        }
    }

    AudioRoute {
        id: route
    }

    SoundEffect {
        id: playMusic
        source: "/usr/share/csd/testdata/sweep_250Hz_5000Hz_250Hz-3dBFS_10s.wav"
        // Set custom category and static volume so we don't interfere with media volume
        category: "csd-loudspeaker-test"
        volume: 0.8
        loops: runInTests ? 1 : SoundEffect.Infinite

        onStatusChanged: {
            if (runInTests) {
                if (status === SoundEffect.Ready) {
                    startTest()
                } else if (status === SoundEffect.Error) {
                    setTestResult(false)
                    testCompleted(true)
                }
            }
        }

        onPlayingChanged: {
            if (runInTests && !playing) {
                setTestResult(true)
                testCompleted(true)
            }
        }
    }

    Label {
        id: stepText

        visible: !runInTests && _testing
        anchors.centerIn: parent
        width: parent.width - 2*Theme.horizontalPageMargin
        font.pixelSize: Theme.fontSizeLarge
        wrapMode: Text.WordWrap
        //% "Is music playing from loudspeaker?"
        text: qsTrId("csd-la-is_music_playing_from_loudspeaker")
    }

    ButtonLayout {
        anchors {
            top: stepText.bottom
            topMargin: Theme.paddingLarge
            horizontalCenter: parent.horizontalCenter
        }
        rowSpacing: Theme.paddingLarge*3
        visible: !runInTests && _testing

        PassButton {
            onClicked: {
                playMusic.stop()
                setTestResult(true)
                testCompleted(true)
            }
        }
        FailButton {
            onClicked: {
                playMusic.stop()
                setTestResult(false)
                testCompleted(true)
            }
        }
    }
}
