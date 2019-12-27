import QtQuick 2.0
import Sailfish.Silica 1.0

Column {
    // client code must set width explicitly or with anchors
    id: root

    // squeezing content a bit. division just good enough approximation.
    spacing: Math.round(-calendarNameLabel.height / 7)

    property alias accountIcon: calendarAccountIcon.source
    property alias calendarName: calendarNameLabel.text
    property alias calendarDescription: calendarDescriptionLabel.text
    property bool selected

    Item {
        width: parent.width
        height: Math.max(calendarAccountIcon.height, calendarNameLabel.height)
        Image {
            id: calendarAccountIcon
            anchors.verticalCenter: parent.verticalCenter
            height: Theme.iconSizeSmall
            width: visible ? Theme.iconSizeSmall : 0
            visible: source != ""
        }
        Label {
            id: calendarNameLabel
            anchors {
                left: calendarAccountIcon.right
                leftMargin: calendarAccountIcon.visible ? Theme.paddingMedium : 0
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: Theme.paddingMedium
            }
            truncationMode: TruncationMode.Fade
            font.pixelSize: Theme.fontSizeLarge
            maximumLineCount: 1
            color: selected ? Theme.highlightColor
                            : (highlighted ? Theme.highlightColor : Theme.primaryColor)
        }
    }
    Label {
        id: calendarDescriptionLabel
        anchors {
            left: parent.left
            right: parent.right
            rightMargin: Theme.paddingMedium
        }
        truncationMode: TruncationMode.Fade
        maximumLineCount: 3
        color: (selected || highlighted) ? Theme.secondaryHighlightColor : Theme.secondaryColor
        visible: text.length > 0
    }
}
