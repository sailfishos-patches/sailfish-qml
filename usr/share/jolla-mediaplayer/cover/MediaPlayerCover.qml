// -*- qml -*-

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.mediaplayer 1.0
import "../scripts/AlbumArtFinder.js" as AlbumArtFinder

CoverBackground {
    id: root

    property alias idle: idleCover
    property string idleArtist
    property string idleSong

    function fetchAlbumArts(count) {
        var artList = []
        for (var i = 0; i < count; ++i) {
            var albumArt = AlbumArtFinder.randomArt(allSongModel, albumArtProvider)
            artList.push(albumArt)
        }
        return artList
    }

    width:  Theme.coverSizeLarge.width
    height: Theme.coverSizeLarge.height

    VisualAudioModel {
        id: visualAudioModel
        modelActive: status != Cover.Inactive
    }

    CoverPlaceholder {
        //: Coverpage text when there are no media
        //% "Get music"
        text: qsTrId("mediaplayer-la-get-music")
        icon.source: "image://theme/icon-launcher-mediaplayer"
        visible: allSongModel.count === 0 && !visualAudioModel.active
    }

    IdleCover {
        id: idleCover
        anchors.fill: parent
        visible: !visualAudioModel.active
    }

    Image {
        id: albumArtImage
        visible: source != "" && visualAudioModel.active
        anchors.fill: parent
        sourceSize.width: width
        sourceSize.height: height
        source: visualAudioModel.metadata && 'url' in visualAudioModel.metadata
                ? albumArtProvider.albumThumbnail(visualAudioModel.metadata.album, visualAudioModel.metadata.artist)
                : ""
        fillMode: Image.PreserveAspectCrop
    }

    Rectangle {
        width: parent.width
        height: column.y + column.height + 2*Theme.paddingLarge
        visible: albumArtImage.visible
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, Theme.opacityHigh) }
            GradientStop { position: 0.6; color: Qt.rgba(0, 0, 0, Theme.opacityLow) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Column {
        id: column

        x: Theme.paddingMedium
        y: Theme.paddingMedium
        spacing: Theme.paddingSmall
        visible: allSongModel.count > 0
        width: parent.width - 2*Theme.paddingMedium

        Label {
            id: durationLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: visualAudioModel.duration >= 3600000 ?
                      Format.formatDuration(visualAudioModel.position / 1000, Formatter.DurationLong) :
                      Format.formatDuration(visualAudioModel.position / 1000, Formatter.DurationShort)
            color: (albumArtImage.visible && Theme.colorScheme == Theme.DarkOnLight)
                   ? Theme.highlightFromColor(Theme.highlightColor, Theme.LightOnDark)
                   : Theme.highlightColor
            font.pixelSize: visualAudioModel.duration >= 3600000 ? Theme.fontSizeExtraLarge : Theme.fontSizeHuge
            opacity: visualAudioModel.active ? (visualAudioModel.state === Audio.Paused ? Theme.opacityHigh : 1.0)
                                             : 0.0
        }

        Label {
            id: artistName
            visible: (!albumArtImage.visible && visualAudioModel.active && text != "") || idleArtist != ""
            text: visualAudioModel.metadata && 'url' in visualAudioModel.metadata
                  ? visualAudioModel.metadata.artist
                  : (idleArtist != "" ? idleArtist : "")
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(implicitWidth, parent.width)
            color: durationLabel.color
            truncationMode: TruncationMode.Fade
            font.pixelSize: Theme.fontSizeLarge
            lineHeightMode: Text.FixedHeight
            lineHeight: Theme.itemSizeMedium/2 // to align with clock cover text
            maximumLineCount: 1
        }

        Item {
            width: parent.width
            height: songTitle.height
            visible: visualAudioModel.active || idleSong != ""

            Label {
                id: songTitle
                text: visualAudioModel.metadata && 'url' in visualAudioModel.metadata
                      ? visualAudioModel.metadata.title
                      : (idleSong != "" ? idleSong : "")
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(implicitWidth, parent.width)
                maximumLineCount: artistName.visible ? 2 : 3
                color: (albumArtImage.visible && Theme.colorScheme == Theme.DarkOnLight)
                       ? Theme.lightPrimaryColor : Theme.primaryColor
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeLarge
                lineHeightMode: Text.FixedHeight
                lineHeight: Theme.itemSizeMedium/2 // to align with clock cover text
                onLineLaidOut: {
                    // last line can show text as much as there fits
                    if (line.number == maximumLineCount - 1) {
                        line.width = parent.width + 1000
                    }
                }
            }

            OpacityRampEffect {
                offset: 0.5
                // FIXME: OpacityRampEffect spits a warning when
                // songTitle doesn't have an actual text
                sourceItem: songTitle
                enabled: songTitle.implicitWidth > Math.ceil(songTitle.width)
            }
        }

    }

    CoverActionList {
        id: coverActions

        iconBackground: albumArtImage.visible
        enabled: visualAudioModel.active

        CoverAction {
            iconSource: visualAudioModel.state == Audio.Playing ? "image://theme/icon-cover-pause" : "image://theme/icon-cover-play"
            onTriggered: AudioPlayer.playPause()
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-next-song"
            onTriggered: AudioPlayer.playNext(true)
        }
    }

    CoverActionList {
        enabled: !coverActions.enabled && allSongModel.count > 0

        CoverAction {
            iconSource: "image://theme/icon-cover-shuffle"
            onTriggered: AudioPlayer.shuffleAndPlay(allSongModel, allSongModel.count)
        }
    }

    GriloTrackerModel {
        id: allSongModel

        //: placeholder string for albums without a known name
        //% "Unknown album"
        readonly property string unknownAlbum: qsTrId("mediaplayer-la-unknown-album")

        //: placeholder string to be shown for media without a known artist
        //% "Unknown artist"
        readonly property string unknownArtist: qsTrId("mediaplayer-la-unknown-artist")

        query: {
            return AudioTrackerHelpers.getSongsQuery("", {"unknownArtist": unknownArtist, "unknownAlbum": unknownAlbum})
        }

        onFinished: {
            var artList = fetchAlbumArts(3)
            if (artList.length > 0) {
                if (!artList[0].url || artList[0].url == "") {
                    root.idleArtist = artList[0].author ? artList[0].author : unknownArtist
                    root.idleSong = artList[0].title ? artList[0].title : unknownAlbum
                } else {
                    root.idle.largeAlbumArt = artList[0].url
                    root.idle.leftSmallAlbumArt = artList[1] && artList[1].url ? artList[1].url : ""
                    root.idle.rightSmallAlbumArt = artList[2] && artList[2].url ? artList[2].url : ""
                    root.idle.sourcesReady = true
                }
            }
        }
    }
}
