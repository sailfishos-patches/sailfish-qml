import QtQuick 2.0
import Sailfish.Media 1.0
import org.nemomobile.policy 1.0
import org.nemomobile.mpris 1.0

MprisControls {
    id: controls

    property MprisManager mprisManager
    property int _playPauseClicks

    opacity: enabled ? 1.0 : 0.0
    isPlaying: mprisManager.currentService && mprisManager.playbackStatus == Mpris.Playing
    artistAndSongText: {
        var artist = ""
        var song = ""

        if (mprisManager.currentService) {
            var artistTag = Mpris.metadataToString(Mpris.Artist)
            var titleTag = Mpris.metadataToString(Mpris.Title)

            artist = (artistTag in mprisManager.metadata) ? mprisManager.metadata[artistTag].toString() : ""
            song = (titleTag in mprisManager.metadata) ? mprisManager.metadata[titleTag].toString() : ""
        }

        return { "artist": artist, "song": song }
    }
    nextEnabled: mprisManager.currentService && mprisManager.canGoNext
    previousEnabled: mprisManager.currentService && mprisManager.canGoPrevious
    playEnabled: mprisManager.currentService && mprisManager.canPlay
    pauseEnabled: mprisManager.currentService && mprisManager.canPause

    onPlayPauseRequested: {
        if (mprisManager.playbackStatus == Mpris.Playing && mprisManager.canPause) {
            mprisManager.playPause()
        } else if (mprisManager.playbackStatus != Mpris.Playing && mprisManager.canPlay) {
            mprisManager.playPause()
        }
    }
    onNextRequested: if (mprisManager.canGoNext) mprisManager.next()
    onPreviousRequested: if (mprisManager.canGoPrevious) mprisManager.previous()

    Permissions {
        enabled: !!mprisManager.currentService
        applicationClass: "player"

        Resource {
            id: keysResource
            type: Resource.HeadsetButtons
            optional: true
        }
    }

    MediaKey {
        enabled: keysResource.acquired && (controls.playEnabled || controls.pauseEnabled)
        key: Qt.Key_MediaTogglePlayPause
        onReleased: controls.playPauseRequested()
    }
    MediaKey {
        enabled: keysResource.acquired && controls.playEnabled
        key: Qt.Key_MediaPlay
        onReleased: controls.mprisManager.play()
    }
    MediaKey {
        enabled: keysResource.acquired && controls.pauseEnabled
        key: Qt.Key_MediaPause
        onReleased: controls.mprisManager.pause()
    }
    MediaKey {
        enabled: keysResource.acquired && !!controls.mprisManager
        key: Qt.Key_MediaStop
        onReleased: controls.mprisManager.stop()
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
