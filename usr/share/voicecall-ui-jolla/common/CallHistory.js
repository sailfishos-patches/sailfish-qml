.pragma library
.import Sailfish.Silica 1.0 as Silica
.import org.nemomobile.commhistory 1.0 as Comms

function durationText(duration) {
    var dateTime = new Date()
    dateTime.setMinutes(0)
    dateTime.setHours(0)
    dateTime.setSeconds(duration)
    return Qt.formatDateTime(dateTime, "hh:mm:ss")
}

function highlightedDurationText(duration, zeroNumbersColor) {
    var minutes = duration / 60.
    var hasHours = minutes >= 60
    var hasMinutes = duration >= 60

    var dateTime = new Date()
    dateTime.setMinutes(0)
    dateTime.setHours(0)
    dateTime.setSeconds(duration)

    if (duration === 0) {
        return '<font color="%0">%1</font>'.arg(zeroNumbersColor)
                                           .arg(Qt.formatDateTime(dateTime, "hh:mm:ss"))

    } else if (!hasHours && !hasMinutes) {
        return '<font color="%0">%1</font>%2'.arg(zeroNumbersColor)
                                             .arg(Qt.formatDateTime(dateTime, "hh:mm:"))
                                             .arg(Qt.formatDateTime(dateTime, "ss"))
    } else if (!hasHours && hasMinutes) {
        return '<font color="%0">%1</font>%2'.arg(zeroNumbersColor)
                                             .arg(Qt.formatDateTime(dateTime, "hh:"))
                                             .arg(Qt.formatDateTime(dateTime, "mm:ss"))
    } else {
        return Qt.formatDateTime(dateTime, "hh:mm:ss")
    }
}

function formatNumber(number) {
    //% "Private number"
    return (typeof(number) !== "string") ? "" : (number.length > 0 ? number : qsTrId("voicecall-la-private_number"))
}

function callerNameShort(person, phoneNumber) {
    if (person) {
        if (person.primaryName.length > 0) {
            return person.primaryName
        }
        if (person.secondaryName.length > 0) {
            return person.secondaryName
        }
    }
    return formatNumber(phoneNumber)
}
