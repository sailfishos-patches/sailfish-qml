import QtQuick 2.1
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as SilicaPrivate

BackgroundItem {
    id: root

    property alias text: label.text
    property alias description: descriptionLabel.text
    property alias iconSource: icon.source
    property real topPadding: Theme.paddingLarge
    property real bottomPadding: 2*Theme.paddingLarge
    property alias roundedCorners: pressHighlight.roundedCorners

    width: label.implicitWidth + 2*Theme.paddingMedium
    implicitHeight: content.height + topPadding + bottomPadding
    highlightedColor: "transparent"

    SilicaPrivate.BubbleBackground {
        id: pressHighlight

        anchors.fill: parent
        visible: root.highlighted
        opacity: Theme.highlightBackgroundOpacity
        color: palette.highlightBackgroundColor
        radius: Theme.paddingLarge
    }

    Column {
        id: content

        y: topPadding
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        spacing: Theme.paddingSmall

        Icon {
            id: icon
            anchors.horizontalCenter: parent.horizontalCenter
            color: label.color
        }

        Label {
            id: label

            width: parent.width - 2*Theme.paddingMedium
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.Wrap
            textFormat: Text.AutoText
            color: highlighted || !root.enabled ? Theme.highlightColor : Theme.primaryColor
        }

        Label {
            id: descriptionLabel

            width: parent.width - 2*Theme.paddingMedium
            height: text.length > 0 ? implicitHeight : 0
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeSmall
            color: highlighted || !root.enabled ? Theme.secondaryHighlightColor : Theme.secondaryColor
        }
    }
}
