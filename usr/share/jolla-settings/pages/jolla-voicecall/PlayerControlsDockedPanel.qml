import QtQuick 2.0
import QtMultimedia 5.0
import Sailfish.Silica 1.0
import Sailfish.Media 1.0

MediaPlayerControlsPanel {
    id: panel

    property string filePath
    property alias firstNameText: firstNameText.text
    property alias lastNameText: lastNameText.text

    playing: mediaPlayer.playbackState == MediaPlayer.PlayingState
    showMenu: false

    duration: mediaPlayer.duration
    position: mediaPlayer.position
    durationScalar: 1000

    onFilePathChanged: {
        mediaPlayer.stop()
        mediaPlayer.source = filePath

        if (filePath != '') {
            mediaPlayer.play()
        }
    }

    onPlayPauseClicked: playing ? mediaPlayer.pause() : mediaPlayer.play()
    onSliderReleased: {
        mediaPlayer.seek(value)
        mediaPlayer.play()
    }
    onOpenChanged: if (!open) mediaPlayer.pause()

    Row {
        parent: extraContentItem

        spacing: Theme.paddingSmall
        x: (parent.width - width) / 2
        height: Math.max(firstNameText.height, lastNameText.height)

        Label {
            id: firstNameText

            color: Theme.primaryColor
            truncationMode: TruncationMode.Fade
            width: Math.min(implicitWidth, panel.width)
            visible: text
        }
        Label {
            id: lastNameText

            color: Theme.secondaryColor
            truncationMode: TruncationMode.Fade
            width: Math.min(implicitWidth, panel.width - firstNameText.width)
            visible: text && width > 0
        }
    }

    MediaPlayer {
        id: mediaPlayer
    }
}
