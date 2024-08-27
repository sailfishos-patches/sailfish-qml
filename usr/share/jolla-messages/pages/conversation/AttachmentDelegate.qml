import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Thumbnailer 1.0

Thumbnail {
    id: attachment
    opacity: status !== Thumbnail.Null || icon.status !== Image.Null ? 1.0 : 0.0
    width: opacity == 1.0 ? size : 0
    height: width
    sourceSize {
        width: size
        height: size
    }

    property var messagePart
    property bool showRetryIcon
    property int size: Theme.itemSizeLarge
    property bool highlighted
    property bool isThumbnail: messagePart.contentType.substr(0, 6) === "image/"
    property bool isVCard: {
        var type = messagePart.contentType.toLowerCase()
        return type.substr(0, 10) === "text/vcard" || type.substr(0, 12) === "text/x-vcard"
    }

    source: isThumbnail ? messagePart.path : ""

    function mimeToIcon(mimeType) {
        var icon = Theme.iconForMimeType(mimeType)
        return icon === "image://theme/icon-m-file-other" ? "image://theme/icon-m-attach" : icon
    }

    Image {
        id: icon
        anchors.fill: parent
        fillMode: Image.Pad
        source: iconSource()

        function iconSource() {
            if (messagePart === undefined ||
                messagePart.contentType.substr(0, 16) === "application/smil" ||
                messagePart.contentType.substr(0, 10) === "text/plain")
                return ""
            else if (showRetryIcon)
                return "image://theme/icon-m-refresh?" + (message.highlighted ? Theme.highlightColor : Theme.primaryColor)
            else if (isThumbnail && attachment.status !== Thumbnail.Error)
                return ""
            else if (isVCard)
                return "image://theme/icon-m-person" + (highlighted ? "?" + Theme.highlightColor : "")
            else
                return mimeToIcon(messagePart.contentType) + (highlighted ? "?" + Theme.highlightColor : "")
        }

        Rectangle {
            anchors.fill: parent
            z: -1
            color: (showRetryIcon && attachment.status !== Thumbnail.Null) ? Theme.highlightDimmerColor : Theme.highlightColor
            opacity: (showRetryIcon && attachment.status !== Thumbnail.Null) ? Theme.opacityHigh : Theme.opacityFaint
            visible: icon.status === Image.Ready
        }
    }
}

