import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: functionItem

    property bool coverMode
    property alias text: label.text

    height: label.height + 2 * Theme.paddingSmall
    width: Math.max(layoutMultiplier/2 * squareWidth, label.width + 2*(coverMode ? Theme.paddingSmall : Theme.paddingMedium))
    Label {
        id: label
        color: Theme.highlightColor
        font.pixelSize: secondaryFontSize
        anchors.verticalCenter: parent.verticalCenter
        x: parent.width - width
    }
}
