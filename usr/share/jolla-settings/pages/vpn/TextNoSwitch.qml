import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0

MouseArea {
    id: root

    property alias text: label.text
    property alias description: desc.text

    property real leftMargin: Theme.horizontalPageMargin
    property real rightMargin: Theme.horizontalPageMargin
    property bool down: pressed && containsMouse && !DragFilter.canceled
    property bool highlighted: down
    property bool visibleIntent: true

    visible: visibleIntent || transition.running

    width: parent.width
    implicitHeight: Math.max(Theme.itemSizeSmall, desc.y + desc.height)

    property real toggleWidth: visibleIntent ? root.leftMargin
                                             : (Theme.itemSizeExtraSmall
                                                + (Theme.colorScheme === Theme.DarkOnLight ? Theme.paddingMedium : 0))
    Behavior on toggleWidth { NumberAnimation { id: transition; duration: 200; easing.type: Easing.InOutQuad } }

    // Appearance is designed to match TextSwitch without the glass item
    Label {
        id: label
        width: parent.width - toggleWidth - root.leftMargin - root.rightMargin
        opacity: root.enabled ? 1.0 : Theme.opacityLow
        x: toggleWidth
        // Center on the first line if there are multiple lines
        y: Math.round(((Theme.itemSizeSmall - implicitHeight) / 2) + (lineCount > 1 ? (lineCount-1)*height/lineCount/2 : 0))
        wrapMode: Text.Wrap
        color: highlighted ? Theme.highlightColor : Theme.primaryColor
    }
    Label {
        id: desc
        width: label.width
        height: text.length ? (implicitHeight + Theme.paddingMedium) : 0
        opacity: root.enabled ? 1.0 : Theme.opacityLow
        anchors.top: label.bottom
        anchors.left: label.left
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSizeExtraSmall
        color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
    }
}
