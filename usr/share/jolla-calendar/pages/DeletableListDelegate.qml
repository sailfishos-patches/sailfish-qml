import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0
import Calendar.syncHelper 1.0

EventListDelegate {
    id: root

    property Item _remorse

    menu: Component {
        ContextMenu {
            id: contextMenu
            width: root.width
            x: 0
            MenuLabel {
                visible: model.event.readOnly
                //% "This event cannot be modified"
                text: qsTrId("calendar-event-event_cannot_be_modified")
            }

            MenuItem {
                visible: !model.event.readOnly && !model.event.externalInvitation
                // "Edit"
                text: qsTrId("calendar-day-edit")
                onClicked: {
                    // TODO: should recurrence exception (recurrence id exists) allow to modify main event?
                    if (model.event.recur != CalendarEvent.RecurOnce) {
                        pageStack.animatorPush("EventEditRecurringPage.qml", { event: model.event,
                                                                       occurrence: model.occurrence })
                    } else {
                        pageStack.animatorPush("EventEditPage.qml", { event: model.event })
                    }
                }
            }
            MenuItem {
                visible: !model.event.readOnly
                //% "Delete"
                text: qsTrId("calendar-day-delete")
                onClicked: {
                    // TODO: on recurrence exception, this just deletes the exception. Doesn't ask to delete series.
                    if (model.event.recur != CalendarEvent.RecurOnce) {
                        pageStack.animatorPush("EventDeletePage.qml",
                                               {   uniqueId: model.event.uniqueId,
                                                   recurrenceId: model.event.recurrenceId,
                                                   calendarUid: model.event.calendarUid,
                                                   startTime: model.occurrence.startTime
                                               })
                    } else {
                        contextMenu.parent.deleteActivated()
                    }
                }
            }
        }
    }

    Connections {
        id: dayConnection
        ignoreUnknownSignals: true
        onStartDateChanged: {
            target = null
            if (_remorse && _remorse.pending) {
                _remorse.cancel()
                Calendar.remove(model.event.uniqueId, model.event.recurrenceId)
                app.syncHelper.triggerUpdateDelayed(model.event.calendarUid)
            }
        }
    }

    function deleteActivated() {
        // Assuming id/property. Need to trigger deletion before day change refreshes content.
        // RemorseItem itself would try to execute its command, but model target might be already deleted.
        dayConnection.target = view.model
        _remorse = remorseDelete(function() {
            Calendar.remove(model.event.uniqueId, model.event.recurrenceId)
            app.syncHelper.triggerUpdateDelayed(model.event.calendarUid)
        })
    }
}

