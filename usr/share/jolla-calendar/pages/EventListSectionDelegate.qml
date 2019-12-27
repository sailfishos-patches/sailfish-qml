import QtQuick 2.0
import Sailfish.Silica 1.0
import "Util.js" as Util

Item {
    id: root

    signal clicked

    height: label.height
    anchors.right: parent.right

    BackgroundItem {
        id: backgroundItem
        anchors.centerIn: label

        width: label.width + 2 * Theme.paddingMedium
        height: Math.min(label.height + Theme.paddingSmall, Theme.itemSizeExtraSmall)
        onClicked: root.clicked()
    }
    Label {
        id: label
        anchors.right: parent.right
        anchors.rightMargin: Theme.paddingLarge
        text: Util.formatDateWeekday(section)
        color: backgroundItem.highlighted ? Theme.highlightColor : Theme.primaryColor
        font.pixelSize: Theme.fontSizeLarge
    }
}
