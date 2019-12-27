import QtQuick 2.0
import Sailfish.Silica 1.0
import "../common"
import "../common/DateUtils.js" as DateUtils

Item {
    property real timeTextWidth: timeText.width
    property real prePadding
    property real postPadding
    property QtObject timerClock

    Label {
        id: timeText

        anchors {
            left: parent.left
            leftMargin: prePadding + Theme.paddingSmall
            verticalCenter: parent.verticalCenter
        }

        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeExtraSmall
        text: DateUtils.formatDuration(timerClock.remaining)
    }

    Label {
        id: timerTitle

        anchors {
            left: timeText.right
            leftMargin: postPadding
            right: parent.right
            verticalCenter: parent.verticalCenter
        }

        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeExtraSmall
        text: model.title
        truncationMode: TruncationMode.Fade
    }
}
