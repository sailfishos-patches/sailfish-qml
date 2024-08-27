import QtQuick 2.0
import Sailfish.Silica 1.0

Label {
    property date startDate
    property date endDate
    property bool allDay
    property bool multiDay: (startDate && endDate)
                            && (startDate.getFullYear() !== endDate.getFullYear()
                                || startDate.getMonth() !== endDate.getMonth()
                                || startDate.getDate() !== endDate.getDate())

    text: {
        var d = startDate
        var result
        if (d.getFullYear() != (new Date).getFullYear()) {
            result = Format.formatDate(d, Format.DateLong)
        } else {
            //% "d MMMM"
            result = Qt.formatDate(d, qsTrId("calendar-date_pattern_date_month"))
        }

        if (!allDay) {
            result += " " + Format.formatDate(startDate, Formatter.TimeValue)
        }

        if (multiDay || !allDay) {
            result += " -"
        }

        if (multiDay) {
            if (d.getFullYear() != (new Date).getFullYear()) {
                result += " " + Format.formatDate(d, Format.DateLong)
            } else {
                //% "d MMMM"
                result += " " + Qt.formatDate(d, qsTrId("calendar-date_pattern_date_month"))
            }
        }

        if (!allDay) {
            result += " " + Format.formatDate(endDate, Formatter.TimeValue)
        }

        return result
    }
}
