import QtQuick 2.1
import Sailfish.Silica 1.0

BackgroundItem {
    height: Theme.itemSizeSmall

    property string title
    property string selectedColor

    Label {
        anchors {
            left: parent.left
            leftMargin: Theme.paddingLarge
            verticalCenter: parent.verticalCenter
        }
        color: parent.down ? Theme.highlightColor : Theme.primaryColor
        width: Math.min(implicitWidth + Theme.paddingMedium, parent.width)
        truncationMode: TruncationMode.Fade
        text: title
    }

    Rectangle {
        anchors {
            right: parent.right
            rightMargin: Theme.paddingLarge
            verticalCenter: parent.verticalCenter
        }
        height: parent.height - Theme.paddingSmall
        width: Theme.itemSizeLarge
        radius: 10
        color: selectedColor
    }
}
