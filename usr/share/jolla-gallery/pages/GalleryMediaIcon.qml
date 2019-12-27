import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.thumbnailer 1.0
import com.jolla.gallery 1.0

MediaSourceIcon {
    id: root

    property int galleryCount: model ? model.count : 0
    property Item _initialThumbnail // required as ListView currentItem is null until index changes

    onTimerTriggered: slideShow.currentIndex = (slideShow.currentIndex + 1) % galleryCount
    timerEnabled: galleryCount > 1
    timerInterval: 8000

    ListView {
        id: slideShow
        interactive: false
        currentIndex: 0
        clip: true
        orientation: ListView.Horizontal
        cacheBuffer: width * 2
        anchors.fill: parent

        model: root.model

        delegate: Thumbnail {
            id: thumbnail

            Component.onCompleted: {
                if (!_initialThumbnail) {
                    _initialThumbnail = thumbnail
                }
            }

            source: model.url
            mimeType: model.mimeType
            width: slideShow.width
            height: slideShow.height
            sourceSize.width: slideShow.width
            sourceSize.height: slideShow.width
        }
    }

    Loader {
        anchors.centerIn: parent
        active: galleryCount === 0
                || (!!slideShow.currentItem && slideShow.currentItem.status === Thumbnail.Error)
                || (!!slideShow._initialThumbnail && slideShow._initialThumbnail.status === Thumbnail.Error)
        sourceComponent: Rectangle {
            width: root.height
            height: root.height
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.rgba(Theme.primaryColor, Theme.opacityFaint) }
                GradientStop { position: 1.0; color: "transparent" }
            }

            Image {
                anchors.centerIn: parent
                source: "image://theme/icon-l-image"
            }
        }
    }
}
