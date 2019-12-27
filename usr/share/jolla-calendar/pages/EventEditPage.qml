import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0
import Sailfish.Calendar 1.0
import Calendar.syncHelper 1.0
import org.nemomobile.notifications 1.0 as SystemNotifications
import org.nemomobile.configuration 1.0
import Sailfish.Silica.private 1.0 as Private

Dialog {
    id: dialog

    property date defaultDate: new Date()
    // if set, edit the event, otherwise create a new one
    property QtObject event
    property bool _isEdit: dialog.event
    property QtObject occurrence
    property bool _replaceOccurrence: dialog.occurrence
    property var saveStartedCb
    property bool attendeesModified

    canAccept: eventName.text != "" && notebookQuery.isValid && dateSelector.valid

    onAcceptBlocked: {
        if (!dateSelector.valid) {
            //% "Event start time needs to be before end time"
            systemNotification.previewBody = qsTrId("jolla-calendar-event_time_problem_notification")
            systemNotification.publish()
        }
    }

    function stripTime(date) {
        return new Date(date.getFullYear(), date.getMonth(), date.getDate())
    }

    function showAttendeePicker() {
        var obj = pageStack.animatorPush(Qt.resolvedUrl("AttendeeSelectionPage.qml"),
                                         {
                                             requiredAttendees: requiredAttendees,
                                             optionalAttendees: optionalAttendees
                                         })
        obj.pageCompleted.connect(function(page) {
            page.modified.connect(function() {
                dialog.attendeesModified = true
            })
        })
    }

    Component {
        id: recurEndDatePicker
        DatePickerDialog {
            canAccept: selectedDate.getTime() >= stripTime(dateSelector.startDate)
        }
    }

    Component {
        id: calendarPicker
        CalendarPicker {
            onCalendarClicked: {
                notebookQuery.targetUid = uid
                selectedCalendarUid = uid
                pageStack.pop()
            }
        }
    }

    SystemNotifications.Notification {
        id: systemNotification

        icon: "icon-lock-calendar"
        isTransient: true
    }

    ConfigurationValue {
        id: reminderConfig

        key: "/sailfish/calendar/default_reminder"
        defaultValue: -1
    }

    ConfigurationValue {
        id: reminderAlldayConfig

        key: "/sailfish/calendar/default_reminder_allday"
        defaultValue: -1
    }

    ContactModel {
        id: requiredAttendees
    }

    ContactModel {
        id: optionalAttendees
    }

    EventQuery {
        property bool initialized

        uniqueId: dialog.event ? dialog.event.uniqueId : ""
        recurrenceId: dialog.event ? dialog.event.recurrenceId: ""

        onAttendeesChanged: {
            // only handle once, query status might fluctuate, JB#32993
            if (initialized || dialog.attendeesModified || attendees.length === 0) {
                return
            }

            for (var i = 0; i < attendees.length; ++i) {
                var attendee = attendees[i]
                // we should be organizer if editing, list only others
                if (attendee.isOrganizer) {
                    continue
                }

                if (attendee.participationRole == Person.RequiredParticipant) {
                    requiredAttendees.append(attendee.name, attendee.email)
                } else {
                    optionalAttendees.append(attendee.name, attendee.email)
                }
            }

            initialized = true
        }
    }

    NotebookQuery {
        id: notebookQuery
        targetUid: dialog._isEdit ? dialog.event.calendarUid : Calendar.defaultNotebook
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: header.height + col.height + Theme.paddingLarge

        DialogHeader {
            id: header

            //% "Save"
            acceptText: qsTrId("calendar-ph-event_edit_save")
        }

        VerticalScrollDecorator {}

        Column {
            id: col

            width: parent.width
            anchors.top: header.bottom

            TextField {
                id: eventName

                //% "Event name"
                placeholderText: qsTrId("calendar-add-event_name")
                label: placeholderText
                width: parent.width
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: eventLocation.focus = true

                Private.AutoFill {
                    id: nameAutoFill
                    key: "calendar.eventName"
                }
            }

            TextField {
                id: eventLocation

                //% "Event location"
                placeholderText: qsTrId("calendar-add-event_location")
                label: placeholderText
                width: parent.width
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: eventDescription.focus = true

                Private.AutoFill {
                    id: locationAutoFill
                    key: "calendar.eventLocation"
                }
            }

            TextArea {
                id: eventDescription

                //% "Description"
                placeholderText: qsTrId("calendar-add-description")
                label: placeholderText
                width: parent.width
            }

            ValueButton {
                id: attendeeButton

                // TODO: we should have some property on notebooks telling whether they support
                // creating invitations. For the moment let's just disable for local calendars.
                enabled: !notebookQuery.localCalendar
                label: (requiredAttendees.count + optionalAttendees.count > 0)
                       ? //% "%n people invited"
                         qsTrId("calendar-invited_people", requiredAttendees.count + optionalAttendees.count)
                       : //% "Invite people"
                         qsTrId("calendar-invite_people")
                //% "You cannot invite people to a local calendar event"
                description: notebookQuery.localCalendar ? qsTrId("calendar-cannot_invite_people") : ""
                value: concatenateAttendees([requiredAttendees, optionalAttendees])
                onClicked: showAttendeePicker()

                function concatenateAttendees(models) {
                    var result = ""
                    for (var i = 0; i < models.length; ++i) {
                        var model = models[i]

                        for (var j = 0; j < model.count; ++j) {
                            var displayName = model.name(j)
                            if (displayName.length == 0) {
                                displayName = model.email(j)
                            }
                            if (result.length !== 0) {
                                result += ", "
                            }
                            result += displayName
                        }
                    }

                    return result
                }
            }

            TimeRangeSelector {
                id: dateSelector

                readonly property bool valid: dateSelector.allDay ? (stripTime(startDate) <= stripTime(endDate))
                                                                  : startDate <= endDate
                showError: !valid
                allDay: allDay.checked

                function handleStartTimeModification(newStartTime, dateChange) {
                    var wasValid = valid
                    var diff = newStartTime.getTime() - startDate.getTime()
                    setStartDate(newStartTime)

                    if (wasValid) {
                        var newEnd = new Date(dateSelector.endDate.getTime() + diff)
                        dateSelector.setEndDate(newEnd)
                    }

                    if (!isNaN(recurEnd.recurEndDate.getTime()) && recurEnd.recurEndDate < startDate) {
                        if (recur.value != CalendarEvent.RecurOnce) {
                            recurEnd.recurEndDate = startDate

                            //: System notification for recurrence end date moved due to user selecting event start date
                            //: after the earlier value
                            //% "Recurrence end date moved to event start date"
                            systemNotification.previewBody = qsTrId("jolla-calendar-recurrence_end_moved_notification")
                            systemNotification.publish()
                        } else {
                            recurEnd.recurEndDate = new Date(NaN) // just clear it, not visible
                        }
                    }
                }
            }

            Item {
                width: 1
                height: Theme.paddingSmall
            }

            CalendarSelector {
                id: calendar

                // prevent modifying notebook for existing event until qml plugin is fixed to create new uid for event
                // ... and always disable for editing single occurrence
                enabled: !dialog._isEdit

                //: Shown as placeholder for non-existant notebook, e.g. when default notebook has been deleted
                //% "(none)"
                name: !notebookQuery.isValid ? qsTrId("calendar-nonexistant_notebook")
                                             : notebookQuery.name
                localCalendar: notebookQuery.localCalendar
                description: notebookQuery.description
                color: notebookQuery.isValid ? notebookQuery.color : "transparent"
                accountIcon: notebookQuery.isValid ? notebookQuery.accountIcon : ""

                onClicked: pageStack.animatorPush(calendarPicker, {"selectedCalendarUid": notebookQuery.targetUid})
            }

            TextSwitch {
                id: allDay

                //% "All day"
                text: qsTrId("calendar-add-all_day")
            }

            ComboBox {
                id: recur

                property int value: currentItem ? currentItem.value : CalendarEvent.RecurOnce

                visible: !dialog._replaceOccurrence && (!dialog._isEdit || dialog.event.recurrenceId.length === 0)

                //% "Recurring"
                label: qsTrId("calendar-add-recurring")
                menu: ContextMenu {
                    MenuItem {
                        property int value: CalendarEvent.RecurOnce
                        //% "Once"
                        text: qsTrId("calendar-add-once")
                    }
                    MenuItem {
                        property int value: CalendarEvent.RecurDaily
                        //% "Every Day"
                        text: qsTrId("calendar-add-every_day")
                    }
                    MenuItem {
                        property int value: CalendarEvent.RecurWeekly
                        //% "Every Week"
                        text: qsTrId("calendar-add-every_week")
                    }
                    MenuItem {
                        property int value: CalendarEvent.RecurBiweekly
                        //% "Every 2 Weeks"
                        text: qsTrId("calendar-add-every_2_weeks")
                    }
                    MenuItem {
                        property int value: CalendarEvent.RecurMonthly
                        //% "Every Month"
                        text: qsTrId("calendar-add-every_month")
                    }
                    MenuItem {
                        property int value: CalendarEvent.RecurYearly
                        //% "Every Year"
                        text: qsTrId("calendar-add-every_year")
                    }
                    MenuItem {
                        visible: false // not used at the moment. remove?
                        property int value: CalendarEvent.RecurCustom
                        //% "Custom"
                        text: qsTrId("calendar-add-custom")
                    }
                }
            }

            ValueButton {
                id: recurEnd

                property date recurEndDate

                visible: recur.value != CalendarEvent.RecurOnce
                //: Picker for recurrence end date
                //% "Recurrence end"
                label: qsTrId("calendar-add-recurrence_end")
                value: Qt.formatDate(recurEndDate)
                onClicked: {
                    var defaultDate = recurEnd.recurEndDate
                    if (isNaN(defaultDate.getTime())) {
                        defaultDate = dateSelector.endDate
                        if (recur.value == CalendarEvent.RecurYearly) {
                            defaultDate.setFullYear(defaultDate.getFullYear() + 1)
                        } else {
                            defaultDate.setMonth(defaultDate.getMonth() + 1)
                        }
                    }

                    var obj = pageStack.animatorPush(recurEndDatePicker, { date: defaultDate })
                    obj.pageCompleted.connect(function(dialog) {
                        dialog.accepted.connect(function() {
                            recurEnd.recurEndDate = dialog.date
                        })
                    })
                }
            }

            ComboBox {
                id: reminder

                property int value: currentItem ? currentItem.seconds : -1
                property bool followSettings
                property bool _applyingSettings

                onFollowSettingsChanged: {
                    if (followSettings) {
                        updateFromSettings()
                    }
                }

                onCurrentIndexChanged: {
                    // modifications stops following settings values
                    if (!_applyingSettings)
                        followSettings = false
                }

                function updateFromSettings() {
                    _applyingSettings = true
                    setFromSeconds(allDay.checked ? reminderAlldayConfig.value
                                                  : reminderConfig.value)
                    _applyingSettings = false
                }

                function setFromSeconds(seconds) {
                    if (seconds < 0) {
                        currentIndex = 0 // ReminderNone
                    } else if (seconds === 0) {
                        currentIndex = 1 // ReminderTime
                    } else {
                        for (var i = menu.children.length - 1; i >= 2; --i) {
                            if (seconds >= menu.children[i].seconds) {
                                currentIndex = i
                                return
                            }
                        }
                    }
                }

                Connections {
                    target: allDay
                    onCheckedChanged: {
                        if (reminder.followSettings) {
                            reminder.updateFromSettings()
                        }
                    }
                }

                //% "Remind me"
                label: qsTrId("calendar-add-remind_me")
                menu: ContextMenu {
                    ReminderMenuItem {
                        seconds: -1 // ReminderNone
                    }
                    ReminderMenuItem {
                        seconds: 0 // ReminderTime
                    }
                    ReminderMenuItem {
                        seconds: 5 * 60 // Reminder5Min
                    }
                    ReminderMenuItem {
                        seconds: 15 * 60 // Reminder15Min
                    }
                    ReminderMenuItem {
                        seconds: 30 * 60 // Reminder30Min
                    }
                    ReminderMenuItem {
                        seconds: 60 * 60 // Reminder1Hour
                    }
                    ReminderMenuItem {
                        seconds: 2 * 60 * 60 // Reminder2Hour
                    }
                    ReminderMenuItem {
                        seconds: 24 * 60 * 60 // Reminder1Day
                    }
                    ReminderMenuItem {
                        seconds: 2 * 24 * 60 * 60 // Reminder2Day
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        if (event) {
            eventName.text = event.displayLabel
            eventDescription.text = event.description
            eventLocation.text = event.location

            if (!dialog._replaceOccurrence) {
                switch (event.recur) {
                case CalendarEvent.RecurOnce: recur.currentIndex = 0; break;
                case CalendarEvent.RecurDaily: recur.currentIndex = 1; break;
                case CalendarEvent.RecurWeekly: recur.currentIndex = 2; break;
                case CalendarEvent.RecurBiweekly: recur.currentIndex = 3; break;
                case CalendarEvent.RecurMonthly: recur.currentIndex = 4; break;
                case CalendarEvent.RecurYearly: recur.currentIndex = 5; break;
                case CalendarEvent.RecurCustom: break;
                }
            }

            reminder.setFromSeconds(event.reminder)
            recurEnd.recurEndDate = event.recurEndDate

            if (dialog._replaceOccurrence) {
                dateSelector.setStartDate(dialog.occurrence.startTime)
                dateSelector.setEndDate(dialog.occurrence.endTime)
            } else  {
                dateSelector.setStartDate(event.startTime)
                dateSelector.setEndDate(event.endTime)
            }

            allDay.checked = event.allDay

        } else {
            eventName.focus = true

            var date = defaultDate
            dateSelector.setStartDate(date)
            date.setHours(date.getHours() + 1)
            dateSelector.setEndDate(date)
            reminder.followSettings = true
        }
    }

    onAccepted: {
        var modification = dialog._isEdit ? Calendar.createModification(dialog.event)
                                          : Calendar.createNewEvent()
        modification.displayLabel = eventName.text
        modification.location = eventLocation.text
        modification.description = eventDescription.text
        modification.recur = recur.value

        if (recur.value == CalendarEvent.RecurOnce) {
            modification.unsetRecurEndDate()
        } else {
            modification.setRecurEndDate(recurEnd.recurEndDate)
        }

        modification.reminder = reminder.value

        if (allDay.checked) {
            modification.setStartTime(stripTime(dateSelector.startDate), CalendarEvent.SpecClockTime)
            modification.setEndTime(stripTime(dateSelector.endDate), CalendarEvent.SpecClockTime)
            modification.allDay = true
        } else {
            modification.setStartTime(dateSelector.startDate, CalendarEvent.SpecLocalZone)
            modification.setEndTime(dateSelector.endDate, CalendarEvent.SpecLocalZone)
            modification.allDay = false
        }

        modification.calendarUid = notebookQuery.targetUid

        if (dialog.attendeesModified && attendeeButton.enabled) {
            modification.setAttendees(requiredAttendees, optionalAttendees)
        }

        if (_replaceOccurrence) {
            var changes = modification.replaceOccurrence(dialog.occurrence)

            if (saveStartedCb) {
                saveStartedCb(changes)
            }

        } else {
            modification.save()
        }
        nameAutoFill.save()
        locationAutoFill.save()

        // When new event is created to calendar mark that calendar as default, and save reminder
        if (!dialog._isEdit) {
            Calendar.defaultNotebook = notebookQuery.targetUid
            if (modification.allDay) {
                reminderAlldayConfig.value = reminder.value
            } else {
                reminderConfig.value = reminder.value
            }
        }

        app.syncHelper.triggerUpdateDelayed(modification.calendarUid)
    }
}
