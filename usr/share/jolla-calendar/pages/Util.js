.pragma library
.import Sailfish.Silica 1.0 as S
.import org.nemomobile.calendar 1.0 as C

function formatDateWeekday(d) {
    var t = new Date
    var t2 = new Date(d)
    var today = new Date(t.getFullYear(), t.getMonth(), t.getDate())
    var day = new Date(t2.getFullYear(), t2.getMonth(), t2.getDate())

    var tcol = (t.getDay() + 6) % 7
    var t2col = (t2.getDay() + 6) % 7

    var delta = (day - today) / 86400000

    if (delta == 0) {
        //% "Today"
        return qsTrId("calendar-today")
    } else if (delta == -1) {
        //% "Yesterday"
        return qsTrId("calendar-yesterday")
    } else if (delta == 1) {
        //% "Tomorrow"
        return qsTrId("calendar-tomorrow")
    } else if (delta <= -7 || delta >= 7 ||
               (delta < 0 && t2col > tcol) ||
               (delta > 0 && tcol > t2col)) {
        //: Long date pattern without year. Used e.g. in month view.
        //% "d MMMM"
        return capitalize(Qt.formatDate(d, qsTrId("calendar-date_pattern_date_month")))
    } else {
        return capitalize(S.Format.formatDate(d, S.Format.WeekdayNameStandalone))
    }
}

function capitalize(string) {
    return string.charAt(0).toUpperCase() + string.substr(1)
}
