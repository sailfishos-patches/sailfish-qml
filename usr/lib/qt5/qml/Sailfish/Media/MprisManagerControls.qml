import QtQuick 2.0
import Sailfish.Media 1.0
import Nemo.Policy 1.0
import Amber.Mpris 1.0

MprisControls {
    id: controls

    property MprisController mprisController
    property int _playPauseClicks

    opacity: enabled ? 1.0 : 0.0
    isPlaying: mprisController.playbackStatus == Mpris.Playing
    artistAndSongText: ({
        "artist": (mprisController.metaData.contributingArtist || '').toString(),
        "song": mprisController.metaData.title || '',
    })
    applicationName: mprisController.identity
    albumArtSource: mprisController.metaData.artUrl || ''

    nextEnabled: mprisController.canGoNext
    previousEnabled: mprisController.canGoPrevious
    playEnabled: mprisController.canPlay
    pauseEnabled: mprisController.canPause

    onPlayPauseRequested: {
        if (mprisController.playbackStatus == Mpris.Playing && mprisController.canPause) {
            mprisController.playPause()
        } else if (mprisController.playbackStatus != Mpris.Playing && mprisController.canPlay) {
            mprisController.playPause()
        }
    }
    onNextRequested: if (mprisController.canGoNext) mprisController.next()
    onPreviousRequested: if (mprisController.canGoPrevious) mprisController.previous()

    Permissions {
        enabled: !!mprisController.currentService
        applicationClass: "player"

        Resource {
            id: keysResource
            type: Resource.HeadsetButtons
            optional: true
        }
    }

    MediaKey {
        enabled: keysResource.acquired && controls.playEnabled
        key: Qt.Key_MediaTogglePlayPause
        onReleased: controls.playPauseRequested()
    }
    MediaKey {
        enabled: keysResource.acquired && controls.playEnabled
        key: Qt.Key_MediaPlay
        onReleased: controls.mprisController.play()
    }
    MediaKey {
        enabled: keysResource.acquired && controls.pauseEnabled
        key: Qt.Key_MediaPause
        onReleased: controls.mprisController.pause()
    }
    MediaKey {
        enabled: keysResource.acquired && !!controls.mprisController
        key: Qt.Key_MediaStop
        onReleased: controls.mprisController.stop()
    }
    MediaKey {
        enabled: keysResource.acquired && controls.nextEnabled
        key: Qt.Key_MediaNext
        onReleased: controls.nextRequested()
    }
    MediaKey {
        enabled: keysResource.acquired && controls.previousEnabled
        key: Qt.Key_MediaPrevious
        onReleased: controls.previousRequested()
    }
    MediaKey {
        enabled: keysResource.acquired
        key: Qt.Key_ToggleCallHangup
        onReleased: {
            if (controls._playPauseClicks < 3) {
                playPauseTimer.restart()
                controls._playPauseClicks += 1
            }
        }
    }

    Timer {
        id: playPauseTimer

        interval: 250

        onTriggered: {
            if (controls._playPauseClicks == 1) {
                controls.playPauseRequested()
            } else if (controls._playPauseClicks == 2) {
                if (controls.nextEnabled) {
                    controls.nextRequested()
                }
            } else if (controls._playPauseClicks >= 3) {
                if (controls.previousEnabled) {
                    controls.previousRequested()
                }
            }
            controls._playPauseClicks = 0
        }
    }
}
