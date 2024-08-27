import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Calendar 1.0
import Nemo.DBus 2.0

DBusAdaptor {
    service: "com.jolla.calendar.ui"
    path: "/com/jolla/calendar/ui"
    iface: "com.jolla.calendar.ui"

    function viewEvent(notebookId, id, recurrenceId, startDate) {
        viewEventByIdentifier(CalendarUtils.instanceId(notebookId, id, recurrenceId), startDate)
    }

    function viewEventByIdentifier(id, startDate) {
        var occurrence = CalendarUtils.parseTime(startDate)
        if (isNaN(occurrence.getTime())) {
            console.warn("Invalid event start date, unable to show event")
            return
        }

        if (pageStack.currentPage.objectName === "EventViewPage") {
            pageStack.currentPage.instanceId = id
            pageStack.currentPage.startTime = occurrence
        } else {
            pageStack.push("pages/EventViewPage.qml",
                           { instanceId: id, startTime: occurrence },
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

        var page = pageStack.find(function(page) {
            return page.objectName === "CalendarPage"
        })
        if (page) {
            page.gotoDate(parsedDate)
            pageStack.pop(page, PageStackAction.Immediate)
        } else {
            console.warn("Cannot find CalendarPage in the stack")
        }
        requestActive.start()
    }

    function importFile(fileName) {
        if (pageStack.currentPage.objectName === "ImportPage") {
            pageStack.currentPage.fileName = fileName
            pageStack.currentPage.icsString = ""
        } else {
            pageStack.push("pages/ImportPage.qml", { "fileName": fileName }, PageStackAction.Immediate)
        }
        requestActive.start()
    }

    function importIcsData(icsString) {
        if (pageStack.currentPage.objectName === "ImportPage") {
            pageStack.currentPage.icsString = icsString
            pageStack.currentPage.fileName = ""
        } else {
            pageStack.push("pages/ImportPage.qml", { "icsString": icsString }, PageStackAction.Immediate)
        }
        requestActive.start()
    }

    function openUrl(arguments) {
        if (arguments.length === 0) {
            app.activate()
        } else {
            importFile(arguments[0])
        }
    }

    function activateWindow(arg) {
        app.activate()
    }
}
