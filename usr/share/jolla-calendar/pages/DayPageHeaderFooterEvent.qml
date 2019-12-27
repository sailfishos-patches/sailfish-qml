import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id : root

    property QtObject event
    property date currentDate

    property date _startTime: event && event.occurrence ? event.occurrence.startTime : new Date()
    property bool _showDate: currentDate.getYear() !== _startTime.getYear()
                          || currentDate.getMonth() !== _startTime.getMonth()
                          || currentDate.getDate() !== _startTime.getDate()

    height: event ? Theme.itemSizeSmall : 0
    opacity: event ? 1.0 : 0.0
    visible: opacity > 0.0

    Behavior on height { NumberAnimation { easing.type: "InOutQuad"; duration: 200 } }
    Behavior on opacity { FadeAnimation { } }

    Label {
        id: time
        anchors {
            left: parent.left
            leftMargin: Screen.sizeCategory > Screen.Medium ? Theme.horizontalPageMargin : Theme.paddingSmall
            verticalCenter: parent.verticalCenter
        }
        visible: event && !event.event.allDay
        color: root.highlighted ? Theme.highlightColor : Theme.primaryColor
        font.pixelSize: Theme.fontSizeSmall
        text: Format.formatDate(_startTime, Formatter.TimeValue)
    }

    Rectangle {
        id: calendarColor
        anchors {
            left: time.right; top: parent.top
            bottom: parent.bottom; margins: Theme.paddingMedium
        }
        width: Theme.paddingSmall
        radius: Math.round(width / 3)
        color: event ? event.event.color : "transparent"
    }

    Label {
        anchors {
            left: calendarColor.right; right: date.left
            verticalCenter: parent.verticalCenter
            margins: Theme.paddingMedium
        }
        color: root.highlighted ? Theme.highlightColor : Theme.primaryColor
        font.pixelSize: Theme.fontSizeSmall
        text: event ? event.event.displayLabel : ""
        truncationMode: TruncationMode.Fade
    }

    Label {
        id: date
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            rightMargin: Theme.horizontalPageMargin - Theme.paddingMedium
        }
        color: root.highlighted ? Theme.highlightColor : Theme.primaryColor
        font.pixelSize: Theme.fontSizeSmall
        //% "d MMMM"
        text: event && _showDate ? Qt.formatDate(_startTime, qsTrId("calendar-date_pattern_date_month")) : ""
        opacity: _showDate ? 1.0 : 0.0
        visible: opacity > 0.0
        Behavior on opacity { FadeAnimation { } }
    }
}
