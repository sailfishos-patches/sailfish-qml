import QtQuick 2.0
import Sailfish.Silica 1.0

Label {
    property bool allDay
    property date startTime
    property date endTime
    property date activeDay

    text: {
        if (allDay) {
            //% "All day"
            return qsTrId("calendar-all_day")
        }

        var activeDayStart = new Date(activeDay.getFullYear(), activeDay.getMonth(), activeDay.getDate())
        var tomorrow = new Date(activeDayStart)
        tomorrow.setDate(tomorrow.getDate() + 1)

        var _start = startTime
        var _end = endTime

        if (startTime < activeDayStart) {
            if (endTime > tomorrow) {
                return qsTrId("calendar-all_day")
            }

            _start = activeDayStart
        }

        if (endTime > tomorrow) {
            _end = activeDayStart
            _end.setHours(23, 59)
        }

        return (Format.formatDate(_start, Formatter.TimeValue) + "-"
                + Format.formatDate(_end, Formatter.TimeValue))
    }
}

