// -*- qml -*-

import QtQuick 2.0
import Sailfish.Silica 1.0

ListItem {
    id: playlistItem

    property color color: Theme.overlayBackgroundColor
    property color highlightColor: Theme.highlightBackgroundColor

    width: Theme.itemSizeExtraLarge
    contentHeight: Theme.itemSizeExtraLarge
    onClicked: pageStack.animatorPush(Qt.resolvedUrl("PlaylistPage.qml"), {media: media})

    Rectangle {
        id: background

        anchors.fill: parent
        color: playlistItem.highlighted ? playlistItem.highlightColor : playlistItem.color
    }

    Rectangle {
        width: parent.width
        height: parent.height / 2
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, Theme.opacityLow) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0) }
        }
    }

    Image {
        source: "image://theme/graphic-media-playlist-exlarge"
        anchors.bottom: parent.bottom
        anchors.right: parent.right
    }

    Label {
        id: name

        y: Theme.paddingMedium
        x: Theme.paddingLarge
        width: parent.width - x
        truncationMode: TruncationMode.Fade
        color: playlistItem.highlighted ? Theme.highlightColor: Theme.primaryColor
        font.pixelSize: Theme.fontSizeExtraSmall
        text: media.title
    }

    Label {
        anchors.left: name.left
        anchors.right: name.right
        anchors.top: name.bottom
        anchors.topMargin: Theme.paddingSmall
        truncationMode: TruncationMode.Fade
        color: playlistItem.highlighted ? Theme.highlightColor: Theme.primaryColor
        font.pixelSize: Theme.fontSizeLarge
        text: media.childCount
    }
}
