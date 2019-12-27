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
    id: root

    property bool started

    Column {
        width: parent.width
        spacing: Theme.paddingLarge
        CsdPageHeader {
            //% "Headset playback"
            title: qsTrId("csd-he-headset_playback")
        }
        DescriptionItem {
            //% "1. Make sure headset is connected.<br>2. Press 'Start' button."
            text: qsTrId("csd-la-audio_play_music_headset_description")
            visible: !root.started
        }
    }

    BottomButton {
        //% "Start"
        text: qsTrId("csd-la-start")
        visible: !root.started
        enabled: route.wiredOutputConnected
        onClicked: {
            playMusic.play()
            root.started = true
        }
    }

    AudioRoute {
        id: route
    }

    SoundEffect{
        id: playMusic
        source: "/usr/share/csd/testdata/MusicLoop48kHz.wav"
        loops: SoundEffect.Infinite
        // Set custom category and static volume so we don't interfere with media volume
        category: "csd-headset-test"
        volume: 0.5
    }

    Label {
        id: stepText
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSizeLarge
        width: parent.width - 2*Theme.horizontalPageMargin
        wrapMode: Text.WordWrap
        //% "Is music playing from headset?"
        text: qsTrId("csd-la-is_music_playing_from_headset")
        visible: root.started
    }

    ButtonLayout {
        anchors {
            top: stepText.bottom
            topMargin: Theme.paddingLarge
            horizontalCenter: parent.horizontalCenter
        }
        rowSpacing: Theme.paddingLarge*3
        visible: root.started

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
