import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Calendar 1.0
import org.nemomobile.calendar 1.0
import Calendar.syncHelper 1.0
import "Util.js" as Util

Page {
    id: root

    property alias uniqueId: query.uniqueId
    property alias recurrenceId: query.recurrenceId
    property alias startTime: query.startTime

    property Item remorseParent
    property var pendingChanges

    function doDelete(action) {
        if (root.remorseParent) {
            pageStack.pop()
            Remorse.itemAction(root.remorseParent, Remorse.deletedText, action)
        } else {
            Remorse.popupAction(pageStack.previousPage(root), Remorse.deletedText,
                                function() { action() })
            pageStack.pop()
        }
    }

    function saveStarted(changes) {
        if (changes) {
            if (changes.pending) {
                pendingChanges = changes
            } else {
                root.recurrenceId = changed.recurrenceId
                root.uniqueId = changes.uniqueId
                root.startTime = undefined
            }
        }
    }

    function iCalendarName(calendarEntry) {
        // Return a name for this icalendar that can be used as a filename

        // Remove any whitespace
        var noWhitespace = calendarEntry.displayLabel.replace(/\s/g, '')

        // Convert to 7-bit ASCII
        var sevenBit = Format.formatText(noWhitespace, Formatter.Ascii7Bit)
        if (sevenBit.length < noWhitespace.length) {
            // This event's name is not representable in ASCII
            sevenBit = "calendarevent"
        }

        // Remove any characters that are not part of the portable filename character set
        return Format.formatText(sevenBit, Formatter.PortableFilename) + '.ics'
    }

    objectName: "EventViewPage"

    EventQuery {
        id: query

        onEventChanged: {
            if (!query.event) {
                pageStack.pop()
            }
        }
    }

    Connections {
        target: pendingChanges ? pendingChanges : null
        ignoreUnknownSignals: true
        onPendingChanged: {
            if (pendingChanges && !pendingChanges.pending) {
                root.recurrenceId = pendingChanges.recurrenceId
                root.uniqueId = pendingChanges.uniqueId
                root.startTime = undefined
                root.pendingChanges = null
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge

        PullDownMenu {
            visible: query.event && !query.event.readOnly

            MenuItem {
                //% "Delete"
                text: qsTrId("calendar-event-delete")
                onClicked: {
                    if (query.event.recur != CalendarEvent.RecurOnce) {
                        pageStack.animatorPush("EventDeletePage.qml",
                            { uniqueId: query.uniqueId,
                              recurrenceId: query.recurrenceId,
                              calendarUid: query.event.calendarUid,
                              startTime: query.startTime})
                    } else {
                        var uid = root.uniqueId
                        var recurrenceId = root.recurrenceId
                        var calendarUid = query.event.calendarUid
                        var remove = Calendar.remove
                        var helper = app.syncHelper
                        // no time passed, assuming deleting the event
                        root.doDelete(function() {
                            remove(uid, recurrenceId)
                            helper.triggerUpdateDelayed(calendarUid)
                        })
                    }
                }
            }
            MenuItem {
                //% "Share"
                text: qsTrId("calendar-event-share")
                onClicked: {
                    var content = {
                        "data": query.event.iCalendar(),
                        "name": root.iCalendarName(query.event),
                        "type": "text/calendar"
                    }

                    pageStack.animatorPush("Sailfish.TransferEngine.SharePage",
                                           {
                                               //% "Share event"
                                               "header": qsTrId("jolla-calendar-he-share-event"),
                                               "content": content,
                                               "mimeType": "text/calendar",
                                               "serviceFilter": ["sharing", "e-mail"]
                                           })
                }
            }
            MenuItem {
                visible: query.event && !query.event.externalInvitation
                //% "Edit"
                text: qsTrId("calendar-event-edit")
                onClicked: {
                    if (query.event.recur != CalendarEvent.RecurOnce) {
                        pageStack.animatorPush("EventEditRecurringPage.qml", { event: query.event,
                                                   occurrence: query.occurrence,
                                                   saveStartedCb: root.saveStarted })
                    } else {
                        pageStack.animatorPush("EventEditPage.qml", { event: query.event })
                    }
                }
            }
        }

        Column {
            id: col

            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                width: parent.width
                title: query.event ? query.event.displayLabel : ""
                wrapMode: Text.Wrap
            }

            CalendarEventView {
                id: eventDetails

                event: query.event
                occurrence: query.occurrence
                showHeader: false

                Connections {
                    target: query
                    onAttendeesChanged: {
                        eventDetails.setAttendees(query.attendees)
                    }
                }
            }
        }
        VerticalScrollDecorator {}

        ViewPlaceholder {
            id: eventErrorPlaceholder
            enabled: query.eventError
            //% "Event could not be loaded, it may no longer exist"
            text: qsTrId("calendar-la-event_could_not_be_loaded")
        }
    }
}
