import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: field

    property bool coverMode
    property alias text: label.text

    height: label.height + 2 * Theme.paddingSmall
    width: layoutMultiplier/2 * squareWidth
    Label {
        id: label
        color: Theme.highlightColor
        font.pixelSize: secondaryFontSize
        anchors.centerIn: parent
    }
}
