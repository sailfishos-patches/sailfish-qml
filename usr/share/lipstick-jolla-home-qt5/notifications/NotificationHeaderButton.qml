import QtQuick 2.6
import Sailfish.Silica 1.0

MouseArea {
    id: root

    property bool showBackground
    property alias icon: icon
    property alias text: label.text
    readonly property bool down: pressed && containsMouse

    width: Math.max(column.width + 2 * Theme.paddingSmall, Theme.itemSizeSmall + 2*(Theme.horizontalPageMargin - Theme.paddingMedium))
    height: Math.max(column.height + 2 * Theme.paddingSmall, Theme.itemSizeSmall)

    Rectangle {
        z: -1
        visible: showBackground || down
        anchors.fill: parent
        radius: Theme.paddingSmall
        color: down ? Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
                    : Theme.rgba(Theme.primaryColor, Theme.opacityFaint)
    }

    Column {
        id: column

        anchors.centerIn: parent

        Icon {
            id: icon

            anchors.horizontalCenter: parent.horizontalCenter
            highlighted: down
        }

        Label {
            id: label

            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeExtraSmall
            highlighted: down
        }
    }
}
