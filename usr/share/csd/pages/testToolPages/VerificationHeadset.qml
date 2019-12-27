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
    category: "csd-headset-record-test"
    volume: 0.75
    wired: true

    //% "Headset recording"
    title: qsTrId("csd-he-headset_recording")

    //% "1. Make sure headset is connected.<br>2. Press 'Record' to speak headset microphone."
    recordHint: qsTrId("csd-la-verification_headset_description")

    //% "Press 'Play' to check voice from headset."
    playbackHint: qsTrId("csd-la-verification_headset_play_description")
}
