import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    property string iconSource
    property alias text: label.text

    width: parent.width
    height: Math.max(Theme.itemSizeSmall, label.height + 2*Theme.paddingMedium)
    opacity: enabled ? 1.0 : Theme.opacityLow

    Image {
        id: image
        x: Theme.horizontalPageMargin - Theme.paddingMedium
        anchors.verticalCenter: parent.verticalCenter
        source: iconSource + "?" + (highlighted ? Theme.highlightColor : Theme.primaryColor)
    }
    Label {
        id: label
        x: image.x + image.width + Theme.paddingMedium
        width: parent.width - x - Theme.horizontalPageMargin + Theme.paddingMedium
        color: highlighted ? Theme.highlightColor : Theme.primaryColor
        anchors.verticalCenter: parent.verticalCenter
        wrapMode: Text.Wrap
    }
}
