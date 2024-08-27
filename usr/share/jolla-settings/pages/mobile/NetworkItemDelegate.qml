import QtQuick 2.0
import Sailfish.Silica 1.0
import QOfono 0.2

ListItem {
    id: root

    property string status
    property alias name: title.text
    property alias description: descriptionLabel.text
    property real rightMargin: Theme.paddingLarge

    contentHeight: Theme.itemSizeSmall
    enabled: status == "available" || status == "current" || status == "unknown"

    Column {
        opacity: root.enabled ? 1.0 : Theme.opacityLow
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            margins: Theme.paddingLarge
            rightMargin: root.rightMargin
        }

        readonly property bool highlightLabels: status == "current" || highlighted

        Label {
            id: title

            width: parent.width
            color: parent.highlightLabels ? Theme.highlightColor : Theme.primaryColor
            truncationMode: TruncationMode.Fade
        }

        Label {
            id: descriptionLabel

            visible: text !== ""
            width: parent.width
            color: parent.highlightLabels ? Theme.secondaryHighlightColor : Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
            truncationMode: TruncationMode.Fade
        }
    }
}
