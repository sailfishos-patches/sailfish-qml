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

    property bool started
    property string previousPort

    PaCmd {
        id: changePath
    }

    AudioRoute {
        id: route
    }

    function finishTest(success) {
        playMusic.stop()
        setTestResult(success)
        if (previousPort) {
            changePath.setPrimarySinkPort(previousPort)
        }
        testCompleted(true)
    }

    BottomButton {
        //% "Start"
        text: qsTrId("csd-la-start")
        visible: !page.started && !route.wiredOutputConnected
        onClicked: {
            // Change play path to Receiver
            previousPort = changePath.primarySinkActivePort()
            changePath.setPrimarySinkPort("output-earpiece")
            playMusic.play()
            page.started = true
        }
    }

    FailBottomButton {
        visible: !page.started && route.wiredOutputConnected
        //% "Headset detected - test can't be executed"
        reason: qsTrId("csd-la-disabled_headset_detected")
        onClicked: {
            setTestResult(false)
            testCompleted(true)
        }
    }

    Column {
        width: parent.width
        spacing: Theme.paddingLarge
        CsdPageHeader {
            //% "Receiver playback"
            title: qsTrId("csd-he-receiver_playback")
        }
        DescriptionItem {
            //% "1. Make sure headset is not connected.<br>2. Press 'Start' button."
            text: qsTrId("csd-la-audio_play_music_receiver_description")
            visible: !page.started
        }
    }

    SoundEffect{
        id: playMusic
        source: "/usr/share/csd/testdata/sweep_250Hz_5000Hz_250Hz-3dBFS_10s.wav"
        loops: SoundEffect.Infinite
        // Set custom category and static volume so we don't interfere with media volume
        category: "csd-earpiece-test"
        volume: 0.8
    }

    Label {
        id: resultText

        visible: page.started
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSizeLarge
        width: parent.width - 2*Theme.horizontalPageMargin
        wrapMode: Text.Wrap
        //% "Is music playing from receiver?"
        text: qsTrId("csd-la-is_music_playing_from_receiver")
    }

    ButtonLayout {
        visible: page.started
        anchors {
            top: resultText.bottom
            topMargin: Theme.paddingLarge
            horizontalCenter: parent.horizontalCenter
        }
        rowSpacing: Theme.paddingLarge*3

        PassButton {
            onClicked: {
                finishTest(true)
            }
        }
        FailButton {
            onClicked: {
                finishTest(false)
            }
        }
    }
}
