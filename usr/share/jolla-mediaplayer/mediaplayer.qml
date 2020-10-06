// -*- qml -*-

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Media 1.0
import com.jolla.mediaplayer 1.0
import org.nemomobile.thumbnailer 1.0 // register image provider
import Nemo.DBus 2.0
import "cover"
import "pages"

ApplicationWindow {
    id: root

    property Item _dockedPanel
    property alias playlists: playlistManager
    property alias visualAudioAppModel: audioAppModel
    property Item activeMediaSource
    property Component coverOverride: (activeMediaSource && activeMediaSource.hasOwnProperty("cover"))
                                      ? activeMediaSource.cover
                                      : null
    property bool mediaKeyOverride: activeMediaSource
                                    && activeMediaSource.hasOwnProperty("overrideMediaKeys")
                                    && activeMediaSource.overrideMediaKeys

    onActiveMediaSourceChanged: AudioPlayer.mprisPlayerOverride =
                                (activeMediaSource && activeMediaSource.hasOwnProperty("mprisPlayer"))
                                ? activeMediaSource.mprisPlayer
                                : null

    allowedOrientations: Screen.sizeCategory > Screen.Medium
                         ? defaultAllowedOrientations
                         : defaultAllowedOrientations & Orientation.PortraitMask
    _defaultPageOrientations: Orientation.All
    _defaultLabelFormat: Text.PlainText

    cover: coverOverride != null ? coverOverride : Qt.resolvedUrl("cover/MediaPlayerCover.qml")

    bottomMargin: _dockedPanel ? _dockedPanel.visibleSize : 0

    initialPage: Component {
        MainViewPage {
            onMediaSourceActivated: {
                root.activeMediaSource = source
            }
        }
    }

    function dockedPanel() {
        if (!_dockedPanel) _dockedPanel = panelComponent.createObject(contentItem)
        return _dockedPanel
    }

    VisualAudioAppModel {
        id: audioAppModel
        modelActive: root.applicationActive
        onActiveChanged: dockedPanel()
        onModelActiveChanged: {
            if (active) {
                dockedPanel().showControls()
            }
        }
    }

    MediaKeys {
        active: AudioPlayer.active && !root.mediaKeyOverride
    }

    Component {
        id: panelComponent
        MediaPlayerDockedPanel {
            z: 1
            author: audioAppModel.metadata && 'artist' in audioAppModel.metadata ? audioAppModel.metadata.artist : ""
            title: audioAppModel.metadata && 'title' in audioAppModel.metadata ? audioAppModel.metadata.title : ""
            duration: audioAppModel.duration / 1000
            state: audioAppModel.state
            active: audioAppModel.active
            position: audioAppModel.position / 1000
        }
    }

    AlbumArtProvider {
        id: albumArtProvider
        songsModel: allSongModel
    }

    GriloTrackerModel {
        id: allSongModel

        query: AudioTrackerHelpers.getSongsQuery("", {"unknownArtist": "", "unknownAlbum": "" })
    }

    PlaylistManager {
        id: playlistManager
    }

    Component {
        id: playQueuePage
        PlayQueuePage {}
    }

    Connections {
        target: AudioPlayer
        onTryingToPlay: dockedPanel().showControls()
    }

    DBusAdaptor {
        service: "com.jolla.mediaplayer"
        path: "/com/jolla/mediaplayer/ui"
        iface: "com.jolla.mediaplayer.ui"

        function activateWindow(arg) {
            root.activate()
        }

        function openUrl(arg) {
            if (arg[0] == undefined) {
                return false
            }

            AudioPlayer.playUrl(Qt.resolvedUrl(arg[0]))
            if (!pageStack.currentPage || pageStack.currentPage.objectName !== "PlayQueuePage") {
                pageStack.push(playQueuePage, {}, PageStackAction.Immediate)
            }
            dockedPanel().open = true
            activate()

            return true
        }
    }

    // Ensure plugin overrides are disabled when the app shuts down
    Component.onDestruction: activeMediaSource = null
}
