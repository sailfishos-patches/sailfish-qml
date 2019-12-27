/*
 * Copyright (c) 2015 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.2
import QtMultimedia 5.5

Item {
    id: video
    property alias fillMode: videoOut.fillMode
    property alias bufferProgress: player.bufferProgress
    property alias duration: player.duration
    property alias error: player.error
    property alias availability: player.availability
    property alias position: player.position
    property alias source: player.source
    property alias status: player.status
    property alias contentRect: videoOut.contentRect
    property alias loops: player.loops

    signal paused
    signal stopped
    signal playing

    function play() {
        player.play()
    }

    function pause() {
        player.pause()
    }

    function stop() {
        player.stop()
    }

    function seek(offset) {
        player.seek(offset)
    }

    VideoOutput {
        id: videoOut
        anchors.fill: video
        source: player
    }

    MediaPlayer {
        id: player
        onPaused:  video.paused()
        onStopped: video.stopped()
        onPlaying: video.playing()
    }
}
