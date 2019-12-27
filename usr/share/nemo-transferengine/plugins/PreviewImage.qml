import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.thumbnailer 1.0

Item {

    property bool metadataStripped
    property int fileSize
    property alias source: thumbnail.source
    property alias mimeType: thumbnail.mimeType

    Thumbnail {
        id: thumbnail

        sourceSize.width: Screen.width
        sourceSize.height: Screen.height / 3
        fillMode: Thumbnail.PreserveAspectCrop
        width: parent.width
        height: parent.height
        clip: true

        Label {
             anchors.centerIn: parent
             font.pixelSize: root.isPortrait ? Theme.fontSizeLarge : Theme.fontSizeMedium
             color: Theme.secondaryColor
             text: Format.formatFileSize(fileSize)
        }
    }
}
