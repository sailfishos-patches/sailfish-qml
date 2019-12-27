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

RecordPage {
    id: page

    // Set custom category and static volume so we don't interfere with media volume
    category: "csd-above-record-test"
    csdMode: true
    inputSource: Recorder.TopMicrophone
    wired: false

    //% "Audio above microphone"
    title: qsTrId("csd-he-audio_above_microphone")

    //% "1. Make sure headset is not connected.<br>2. Press 'Record' to speak above microphone."
    recordHint: qsTrId("csd-la-audio_top_mic_description")
}
