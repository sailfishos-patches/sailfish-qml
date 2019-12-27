import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: item
    property bool hourMode
    property alias pixelSize: timeLabel.font.pixelSize
    property alias color: timeLabel.color
    property alias text: timeLabel.text
    property alias splitText: splitLabel.text
    property alias secondaryText: secondaryLabel.text
    property bool showSplit
    property bool hiddenSplit

    height: lapColumn.height
    width: lapColumn.width + (showSplit ? splitColumn.width + 2*Theme.paddingLarge : 0)

    Column {
        id: lapColumn
        spacing: -Theme.paddingMedium
        anchors {
            right: parent.horizontalCenter
            rightMargin: showSplit ? Theme.paddingLarge : -width/2
        }

        Label {
            id: timeLabel
            font {
                pixelSize: hourMode ? Theme.fontSizeExtraLarge : Theme.fontSizeHuge
                family: Theme.fontFamilyHeading
            }
        }
        Label {
            id: secondaryLabel
            color: timeLabel.color
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.right: timeLabel.right
        }
    }
    Column {
        id: splitColumn
        visible: showSplit && !hiddenSplit
        spacing: -Theme.paddingMedium
        anchors {
            left: parent.horizontalCenter
            leftMargin: Theme.paddingLarge
        }
        Label {
            id: splitLabel
            color: Theme.secondaryColor
            font {
                pixelSize: timeLabel.font.pixelSize
                family: Theme.fontFamilyHeading
            }
        }
        Label {
            color: splitLabel.color
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.right: splitLabel.right
            text: secondaryLabel.text
        }
    }
}
