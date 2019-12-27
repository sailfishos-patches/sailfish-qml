import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: shortcutItem

    property alias title: title.text
    property string iconSource
    property string actionIconSource

    function imageSource(path) {
        var imagePath = path
        if (path && path[0] != '/' && path.indexOf("://") < 0) {
            imagePath = "image://theme/" + path
        }
        if (imagePath.length > 0) {
            imagePath = imagePath + '?' + (shortcutItem.highlighted ? Theme.highlightColor : Theme.primaryColor)
        }
        return imagePath
    }

    height: Theme.itemSizeSmall
    opacity: enabled ? 1 : Theme.opacityLow
    Behavior on opacity { FadeAnimation {} }

    Image {
        id: icon
        anchors {
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
        }
        source: imageSource(shortcutItem.iconSource)
        visible: source != ''
    }

    Label {
        id: title
        anchors {
            left: icon.right
            leftMargin: icon.visible ? Theme.paddingLarge : 0
            right: actionIcon.left
            rightMargin: actionIcon.visible ? Theme.paddingLarge : 0
            verticalCenter: parent.verticalCenter
        }
        color: shortcutItem.highlighted ? Theme.highlightColor : Theme.primaryColor
        font.pixelSize: Theme.fontSizeMedium
        truncationMode: TruncationMode.Fade
    }

    Image {
        id: actionIcon
        anchors {
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
        }
        source: imageSource(shortcutItem.actionIconSource)
        visible: source != ''
    }
}

