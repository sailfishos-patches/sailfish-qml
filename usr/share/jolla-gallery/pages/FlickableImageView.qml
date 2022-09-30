import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private
import QtMultimedia 5.0
import Sailfish.Gallery 1.0
import com.jolla.gallery 1.0

PagedView {
    id: root

    property bool autoPlay
    property alias viewerOnlyMode: overlay.viewerOnlyMode
    readonly property QtObject player: playerLoader.item ? playerLoader.item.player : null
    readonly property bool playing: player && player.playing

    function triggerViewerAction(action, immediately) {
        overlay.triggerAction(action, immediately)
    }

    Component.onCompleted: if (autoPlay) playerLoader.active = true

    interactive: count > 1 && !(!overlay.active && playing)

    property Item previousItem
    onMovingChanged: {
        if (moving) {
            previousItem = currentItem
        } else if (player && previousItem != currentItem) {
            player.reset()
        }
    }

    delegate: Loader {
        readonly property url source: model.url
        readonly property bool isImage: model.mimeType.indexOf("image/") == 0
        readonly property string itemId: model.itemId !== undefined ? model.itemId : ""
        readonly property int duration: model.duration !== undefined ? model.duration : 1
        readonly property bool isCurrentItem: PagedView.isCurrentItem
        readonly property bool playing: root.playing && isCurrentItem
        readonly property bool error: item && item.error

        // Delay Poster creation until we're in playing state. Without this when auto playing
        // poster will blink at the beginning.
        active: !autoPlay
        onPlayingChanged: {
            if (autoPlay && playing) {
                active = true
            }
        }

        width: root.width
        height: root.height
        sourceComponent: isImage ? imageComponent : videoComponent
        asynchronous: !isCurrentItem

        Component {
            id: imageComponent

            ImageViewer {
                onZoomedChanged: overlay.active = !zoomed
                onClicked: {
                    if (zoomed) {
                        zoomOut()
                    } else {
                        overlay.active = !overlay.active
                    }
                }

                source: model.url
                active: isCurrentItem
                contentRotation: -model.orientation
                viewMoving: root.moving
            }
        }

        Component {
            id: videoComponent

            VideoPoster {
                onClicked: overlay.active = !overlay.active
                onDoubleClicked: overlay.seekForward()

                onTogglePlay: {
                    playerLoader.active = true
                    player.togglePlay()
                }

                source: model.url
                mimeType: model.mimeType
                playing: player && player.playing
                loaded: player && player.loaded
                busy: autoPlay && player && !player.hasVideo && !player.hasError
                onBusyChanged: if (!busy) { busy = false } // remove binding

                contentWidth: root.width
                contentHeight: root.height
                overlayMode: overlay.active
            }
        }
    }


    Loader {
        id: playerLoader

        parent: root.contentItem
        z: -1
        active: false
        width: root.width
        height: root.height
        sourceComponent: GalleryVideoOutput {
            player: GalleryMediaPlayer {
                autoPlay: root.autoPlay
                active: currentItem && !currentItem.isImage && Qt.application.active
                source: active ? currentItem.source : ""
                onPlayingChanged: {
                    if (playing && overlay.active) {
                        // go fullscreen for playback if triggered via Play icon.
                        overlay.active = false
                    }
                }
                onLoadedChanged: if (loaded) playerLoader.anchors.centerIn = currentItem
                onDisplayError: root.currentItem.item.displayError()
            }
        }
    }

    GalleryOverlay {
        id: overlay

        onRemove: {
            var source = overlay.source
            //: Delete an image
            //% "Deleting"
            remorseAction(qsTrId("gallery-la-deleting"), function() {
                fileRemover.deleteFiles([source])
                if (source === overlay.source) pageStack.pop()
            })
        }
        onEdited: window.startPage.showImage([image])
        onCreatePlayer: playerLoader.active = true

        source: currentItem ? currentItem.source : ""
        itemId: currentItem ? currentItem.itemId : ""
        isImage: currentItem ? currentItem.isImage : true
        duration: currentItem ? currentItem.duration : 1
        error: currentItem && currentItem.error

        player: root.player
        anchors.fill: parent
        z: model.count + 100


        Private.DismissButton {}
    }
    FileRemover {
        id: fileRemover
    }
}
