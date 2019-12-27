import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Calendar 1.0
import org.nemomobile.dbus 2.0

DBusAdaptor {
    service: "com.jolla.calendar.ui"
    path: "/com/jolla/calendar/ui"
    iface: "com.jolla.calendar.ui"

    function viewEvent(id, recurrenceId, startDate) {
        var occurrence = CalendarUtils.parseTime(startDate)
        if (isNaN(occurrence.getTime())) {
            console.warn("Invalid event start date, unable to show event")
            return
        }

        if (pageStack.currentPage.objectName === "EventViewPage") {
            pageStack.currentPage.uniqueId = id
            pageStack.currentPage.recurrenceId = recurrenceId
            pageStack.currentPage.startTime = occurrence
        } else {
            pageStack.push("pages/EventViewPage.qml",
                           { uniqueId: id, recurrenceId: recurrenceId, startTime: occurrence },
                           PageStackAction.Immediate)
        }
        requestActive.start()
    }

    function viewDate(dateTime) {
        var parsedDate = new Date(dateTime)
        if (isNaN(parsedDate.getTime())) {
            console.warn("Invalid date, unable to show events for date")
            return
        }

        if (pageStack.currentPage.objectName === "DayPage") {
            pageStack.currentPage.date = parsedDate
        } else {
            pageStack.push("pages/DayPage.qml", { date: parsedDate }, PageStackAction.Immediate)
        }
        requestActive.start()
    }

    function importFile(fileName) {
        if (pageStack.currentPage.objectName === "ImportPage") {
            pageStack.currentPage.fileName = fileName
        } else {
            pageStack.push("pages/ImportPage.qml", { "fileName": fileName }, PageStackAction.Immediate)
        }
        requestActive.start()
    }

    function activateWindow(arg) {
        app.activate()
    }
}
