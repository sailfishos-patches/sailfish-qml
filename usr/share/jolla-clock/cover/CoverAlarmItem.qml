import QtQuick 2.0
import Sailfish.Silica 1.0
import "../common"

Item {
    property alias color: decoration.color
    property alias time: clockItem.time
    property alias title: alarmTitle.text

    property real preTextWidth: clockItem.layoutDirection === Qt.RightToLeft ? clockItem.ampmTextWidth : 0
    property real timeTextWidth: clockItem.timeTextWidth
    property real postTextWidth: clockItem.layoutDirection === Qt.LeftToRight ? clockItem.ampmTextWidth : 0

    property real prePadding
    property real postPadding

    Rectangle {
        id: decoration

        height: Theme.iconSizeSmall
        width: Theme.paddingSmall
        anchors.verticalCenter: parent.verticalCenter
        radius: width/2
    }

    ClockItem {
        id: clockItem

        anchors {
            left: decoration.right
            leftMargin: prePadding
            verticalCenter: parent.verticalCenter
        }

        primaryPixelSize: Theme.fontSizeExtraSmall
    }

    Label {
        id: alarmTitle

        anchors {
            left: clockItem.right
            leftMargin: postPadding
            right: parent.right
            verticalCenter: parent.verticalCenter
        }

        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeExtraSmall
        truncationMode: TruncationMode.Fade
    }
}

