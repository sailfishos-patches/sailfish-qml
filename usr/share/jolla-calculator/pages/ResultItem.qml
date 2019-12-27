import QtQuick 2.0
import Sailfish.Silica 1.0

Rectangle {
    id: resultItem

    property bool coverMode
    property alias text: label.text
    property alias linkText: linkLabel.text
    signal clicked
    signal pressAndHold

    height: label.height + 2 * Theme.paddingLarge * (coverMode ? 0.3 : 1.0)
    width: Math.max(height, label.width + 2*(coverMode ? Theme.paddingMedium : Theme.paddingLarge))
    color: Theme.highlightBackgroundColor

    MouseArea {
        id: mouseArea

        readonly property bool down: pressed && containsMouse
        anchors.fill: parent
        onClicked: resultItem.clicked()
        onPressAndHold: resultItem.pressAndHold()
    }
    Label {
        id: label

        anchors.centerIn: parent
        color: mouseArea.down ? Theme.highlightColor : Theme.primaryColor
        font.pixelSize: primaryFontSize
    }
    LinkLabel {
        id: linkLabel
        coverMode: parent.coverMode
    }
}
