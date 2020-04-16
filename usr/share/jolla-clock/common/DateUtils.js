.pragma library

var oneday = 1000*60*60*24
var onehour = 1000*60*60
var oneminute = 1000*60

function remainingTime(hour, minute, weekdays, currentDate) {
    if (currentDate === undefined) {
        currentDate = new Date()
    }

    var alarmDate = new Date(currentDate.getTime())
    alarmDate.setHours(hour)
    alarmDate.setMinutes(minute)
    alarmDate.setDate(alarmDate.getDate() + daysTo(hour, minute, weekdays, currentDate))
    return alarmDate.getTime() - currentDate.getTime()
}

function daysTo(hour, minute, weekdays, currentDate) {
    var allDays = "mtwTfsS"

    // correct JavaScript index to match our weekday string
    var today = (currentDate.getDay()+6) % allDays.length

    var alarmDate = new Date(currentDate.getTime())
    alarmDate.setHours(hour)
    alarmDate.setMinutes(minute)
    alarmDate.setSeconds(0)
    var earlierToday = currentDate > alarmDate

    var days = 0

    // one-shot alarm
    if (weekdays.length === 0) {
        days = earlierToday ? 1 : 0
    } else {
        var weekday = allDays[today]
        for (var i=0; i < allDays.length; i++) {
            if (weekdays.indexOf(weekday) >= 0) {
                days = i
                if (earlierToday && i === 0) {
                    if (weekdays.length === 1) {
                        // special check for earlier today
                        days = i + 7
                        break
                    } // else continue searching for a closer day
                } else {
                    break
                }
            }
            // try next day
            weekday = allDays[(today + i + 1) % allDays.length]
        }
    }
    return days
}

function days(time) {
    return Math.floor(time/oneday)
}

function hours(time) {
    return Math.floor((time % oneday)/onehour)
}

function minutes(time) {
    return Math.round((time % onehour)/oneminute)
}

function formatDuration(duration) {
    var dateTime = new Date()
    dateTime.setMinutes(0)
    dateTime.setHours(0)
    dateTime.setSeconds(duration)
    return duration > 3600 ? Qt.formatDateTime(dateTime, "hh:mm")
                           : Qt.formatDateTime(dateTime, "mm:ss")
}
