import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    property alias day: dayLabel.text
    property alias weekDay: weekDayLabel.text
    property alias month: monthLabel.text

    width: parent.width
    height: dayLabel.height + dayLabel.y
    Label {
        id: weekDayLabel

        width: parent.width
        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeSmall
        truncationMode: TruncationMode.Fade
        anchors {
            left: parent.left
            right: dayLabel.left
            bottom: monthLabel.top
            bottomMargin: -Theme.paddingSmall
        }
    }
    Label {
        id: monthLabel

        width: parent.width
        font.pixelSize: Theme.fontSizeExtraSmall
        truncationMode: TruncationMode.Fade
        color: Theme.secondaryHighlightColor
        anchors {
            left: parent.left
            right: dayLabel.left
            baseline: dayLabel.baseline
        }
    }
    Label {
        id: dayLabel
        y: Theme.paddingMedium
        font {
            pixelSize: Theme.fontSizeHuge
            family: Theme.fontFamilyHeading
        }
        anchors.right: parent.right
    }
}

