import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Calendar 1.0

Row {
    id: root

    property alias eventName: nameLabel.text
    property alias allDay: timeLabel.allDay
    property alias startTime: timeLabel.startTime
    property alias endtime: timeLabel.endTime
    property alias activeDay: timeLabel.activeDay
    property alias color: rectangle.color
    property alias cancelled: timeLabel.font.strikeout

    spacing: Theme.paddingSmall

    Rectangle {
        id: rectangle

        radius: Theme.paddingSmall/3
        width: Theme.paddingSmall
        height: parent.height - Theme.paddingMedium - Theme.paddingSmall/2
        anchors.verticalCenter: parent.verticalCenter
    }
    Column {
        id: labelColumn
        spacing: -Theme.paddingSmall
        anchors.verticalCenter: parent.verticalCenter
        EventTimeLabel {
            id: timeLabel
            opacity: Theme.opacityHigh
            font.pixelSize: Theme.fontSizeSmall
            verticalAlignment: Text.AlignVCenter
            fontSizeMode: Text.VerticalFit
            height: root.height/2
        }
        Label {
            id: nameLabel
            font.pixelSize: Theme.fontSizeSmall
            verticalAlignment: Text.AlignVCenter
            fontSizeMode: Text.VerticalFit
            height: root.height/2
        }
    }
}
