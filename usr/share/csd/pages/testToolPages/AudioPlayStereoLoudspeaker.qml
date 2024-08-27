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

    AudioRoute {
        id: route
    }

    BottomButton {
        //% "Start"
        text: qsTrId("csd-la-start")
        visible: !page.started && !route.wiredOutputConnected
        onClicked: {
            page.started = true
            playStereo.play()
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
            //% "Stereo loudspeaker playback"
            title: qsTrId("csd-he-stereo_loudspeaker_playback")
        }
        DescriptionItem {
            visible: !page.started
            //% "1. Make sure headset is not connected.<br>2. Press 'Start' button."
            text: qsTrId("csd-la-audio_play_music_loudspeaker_description")
        }
    }

    SoundEffect {
        id: playStereo
        source: "/usr/share/csd/testdata/AudioPlayStereoLoudspeaker.wav"
        // Set custom category and static volume so we don't interfere with media volume
        category: "csd-stereo-loudspeaker-test"
        volume: 1.0
        loops: SoundEffect.Infinite
    }

    Label {
        id: stepText

        visible: page.started
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSizeLarge
        width: parent.width - 2*Theme.horizontalPageMargin
        wrapMode: Text.Wrap
        //% "Was voice speaking 'left speaker' from left loudspeaker and 'right speaker' from right loudspeaker?"
        text: qsTrId("csd-la-is_music_playing_from_stereo_loudspeaker")
    }

    ButtonLayout {
        visible: page.started
        anchors {
            top: stepText.bottom
            topMargin: Theme.paddingLarge
            horizontalCenter: parent.horizontalCenter
        }
        rowSpacing: Theme.paddingMedium

        PassButton {
            onClicked: {
                playStereo.stop()
                setTestResult(true)
                testCompleted(true)
            }
        }
        FailButton {
            onClicked: {
                playStereo.stop()
                setTestResult(false)
                testCompleted(true)
            }
        }
    }
}
