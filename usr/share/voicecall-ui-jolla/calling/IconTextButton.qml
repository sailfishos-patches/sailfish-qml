import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: button

    property alias icon: image
    property alias text: label.text
    property alias description: descriptionLabel.text

    width: Theme.itemSizeHuge
    height: Math.max(Theme.itemSizeHuge, column.height + column.y + Theme.paddingMedium)
    highlightedColor: "transparent"

    Column {
        id: column

        x: Theme.paddingMedium
        width: parent.width - 2 * x
        y: Theme.paddingLarge
        spacing: Theme.paddingSmall

        // Wrap the icon, so that a larger icon can also be aligned with smaller ones
        Item {
            width: Theme.iconSizeMedium
            height: Theme.iconSizeMedium
            anchors.horizontalCenter: parent.horizontalCenter

            Icon {
                id: image
                anchors.centerIn: parent
            }
        }

        Label {
            id: label

            width: parent.width
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeExtraSmall
        }

        Label {
            id: descriptionLabel

            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeSmall
            color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            wrapMode: Text.Wrap
        }
    }
}
