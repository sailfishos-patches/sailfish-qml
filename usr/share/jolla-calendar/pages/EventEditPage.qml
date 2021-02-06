/****************************************************************************
**
** Copyright (C) 2015 - 2019 Jolla Ltd.
** Copyright (C) 2020 Open Mobile Platform LLC.
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0
import Sailfish.Calendar 1.0
import Sailfish.Timezone 1.0
import Calendar.syncHelper 1.0
import org.nemomobile.notifications 1.0 as SystemNotifications
import org.nemomobile.configuration 1.0
import org.nemomobile.systemsettings 1.0
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
            systemNotification.body = qsTrId("jolla-calendar-event_time_problem_notification")
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
            hideExcludedCalendars: true
            onCalendarClicked: {
                notebookQuery.targetUid = uid
                selectedCalendarUid = uid
                pageStack.pop()
            }
        }
    }

    SystemNotifications.Notification {
        id: systemNotification

        appIcon: "icon-lock-calendar"
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
                                result += Format.listSeparator
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

            ValueButton {
                id: timezone
                property int timespec: CalendarEvent.SpecTimeZone
                property string name: timeSettings.timezone
                function set(spec, zone) {
                    if (spec == CalendarEvent.SpecTimeZone && zone !== undefined) {
                        name = zone
                    } else {
                        name = Qt.binding(function() {return timeSettings.timezone})
                    }
                    if (spec == CalendarEvent.SpecLocalZone) {
                        // This is a hack, because KDateTime for local zone
                        // spec is not reacting to tz change. So save as
                        // time zone spec with the right name. To be removed
                        // when kcalcore/ktimezones can react to tz changes,
                        // or kcalcore is upgrade to upstream.
                        timespec == CalendarEvent.SpecTimeZone
                    } else {
                        timespec = spec
                    }
                }
                visible: opacity > 0.
                opacity: allDay.checked ? 0. : 1.
                Behavior on opacity { FadeAnimation {} }
                //% "Time zone"
                label: qsTrId("calendar-choose-timespec")
                value: {
                    switch (timespec) {
                    //% "None"
                    case CalendarEvent.SpecClockTime: return qsTrId("calendar-me-clock_time")
                    //% "Coordinated universal time"
                    case CalendarEvent.SpecUtc: return qsTrId("calendar-me-utc")
                    //: %1 will be replaced by localized country and %2 with localized city
                    //% "%1, %2"
                    case CalendarEvent.SpecTimeZone: return qsTrId("calendar-me-localized-timezone").arg(localizer.country).arg(localizer.city)
                    }
                }
                onClicked: {
                    var obj = pageStack.animatorPush("Sailfish.Timezone.TimezonePicker",
                        {showNoTimezoneOption: true, showUniversalTimeOption: true})
                    obj.pageCompleted.connect(function(page) {
                        page.timezoneClicked.connect(function(zone) {
                            if (zone == "") {
                                timezone.set(CalendarEvent.SpecClockTime)
                            } else if (zone == "UTC") {
                                timezone.set(CalendarEvent.SpecUtc)
                            } else {
                                timezone.set(CalendarEvent.SpecTimeZone, zone)
                            }
                            pageStack.pop()
                        })
                    })
                }
                TimezoneLocalizer {
                    id: localizer
                    timezone: timezone.name
                }
                DateTimeSettings {
                    id: timeSettings
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

                property bool showCustom
                property int value: currentItem ? currentItem.value : CalendarEvent.RecurOnce

                visible: !dialog._replaceOccurrence && (!dialog._isEdit || dialog.event.recurrenceId.length === 0)

                //% "Recurring"
                label: qsTrId("calendar-add-recurring")
                description: value == CalendarEvent.RecurCustom
                    //% "The recurrence scheme is too complex to be shown."
                    ? qsTrId("calendar-add-custom-scheme-explanation") : ""
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
                        property int value: CalendarEvent.RecurWeeklyByDays
                        //% "Every Selected Days"
                        text: qsTrId("calendar-add-every_week_by_days")
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
                        property int value: CalendarEvent.RecurMonthlyByDayOfWeek
                        text: {
                            var dayLabel = Format.formatDate(dateSelector.startDate, Format.WeekdayNameStandalone)
                            var day = dateSelector.startDate.getDate()
                            if (day < 8) {
                                //: %1 is replaced with weekday name
                                //% "First %1 Every Month"
                                return qsTrId("calendar-add-every_month_by_day_of_week_first").arg(dayLabel)
                            } else if (day < 15) {
                                //: %1 is replaced with weekday name
                                //% "Second %1 Every Month"
                                return qsTrId("calendar-add-every_month_by_day_of_week_second").arg(dayLabel)
                            } else if (day < 22) {
                                //: %1 is replaced with weekday name
                                //% "Third %1 Every Month"
                                return qsTrId("calendar-add-every_month_by_day_of_week_third").arg(dayLabel)
                            } else if (day < 29) {
                                //: %1 is replaced with weekday name
                                //% "Fourth %1 Every Month"
                                return qsTrId("calendar-add-every_month_by_day_of_week_fourth").arg(dayLabel)
                            } else {
                                //: %1 is replaced with weekday name
                                //% "Fifth %1 Every Month"
                                return qsTrId("calendar-add-every_month_by_day_of_week_fifth").arg(dayLabel)
                            }
                        }
                    }
                    MenuItem {
                        property int value: CalendarEvent.RecurMonthlyByLastDayOfWeek
                        function addDays(date, days) {
                            var later = new Date(Number(date))
                            later.setDate(date.getDate() + days)
                            return later
                        }
                        visible: addDays(dateSelector.startDate, 7).getMonth() != dateSelector.startDate.getMonth()
                        onVisibleChanged: {
                            if (!visible && recur.value == value) {
                                recur.currentIndex = 6
                            }
                        }
                        text: {
                            var dayLabel = Format.formatDate(dateSelector.startDate, Format.WeekdayNameStandalone)
                            //: %1 is replaced with weekday name
                            //% "Last %1 Every Month"
                            return qsTrId("calendar-add-every_month_by_day_of_week_last").arg(dayLabel)
                        }
                    }
                    MenuItem {
                        property int value: CalendarEvent.RecurYearly
                        //% "Every Year"
                        text: qsTrId("calendar-add-every_year")
                    }
                    MenuItem {
                        visible: recur.showCustom
                        property int value: CalendarEvent.RecurCustom
                        //% "Keep existing scheme"
                        text: qsTrId("calendar-add-keep-scheme")
                    }
                }
            }

            Row {
                id: recurringDays
                // By default, the day of the event is selected.
                property int days: weekModel.model.get((dateSelector.startDate.getDay() + 6) % 7).value
                function flipDay(day) {
                    if (days & day) {
                        days &= ~day
                    } else {
                        days |= day
                    }
                }

                x: Theme.horizontalPageMargin
                visible: recur.value == CalendarEvent.RecurWeeklyByDays

                Repeater {
                    id: weekModel
                    model: ListModel {
                        ListElement { value: CalendarEvent.Monday }
                        ListElement { value: CalendarEvent.Tuesday }
                        ListElement { value: CalendarEvent.Wednesday }
                        ListElement { value: CalendarEvent.Thursday }
                        ListElement { value: CalendarEvent.Friday }
                        ListElement { value: CalendarEvent.Saturday }
                        ListElement { value: CalendarEvent.Sunday }
                    }
                    MouseArea {
                        property bool down: (pressed && containsMouse) || (dot.pressed && dot.containsMouse)

                        width: (col.width - 2 * Theme.horizontalPageMargin) / 7
                        height: childrenRect.height

                        onClicked: recurringDays.flipDay(model.value)

                        Switch {
                            id: dot
                            y: -Theme.paddingLarge
                            width: parent.width
                            highlighted: down
                            automaticCheck: false
                            checked: recurringDays.days & model.value
                            down: parent.down
                            onClicked: recurringDays.flipDay(model.value)
                        }
                        Label {
                            anchors {
                                horizontalCenter: dot.horizontalCenter
                                top: dot.bottom
                                topMargin: -Theme.paddingLarge
                            }
                            // 2020 April 20th is a Monday
                            text: Qt.formatDateTime(new Date(2020, 3, 20 + model.index), "ddd")
                            font.pixelSize: Theme.fontSizeSmall
                            color: dot.highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
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
                        for (var i = reminderValues.model.length - 1; i >= 2; --i) {
                            if (seconds == reminderValues.model[i]) {
                                currentIndex = i
                                return
                            } else if (seconds > reminderValues.model[i]) {
                                var tmp = reminderValues.model
                                tmp.splice(i + 1, 0, seconds)
                                reminderValues.model = tmp
                                currentIndex = i + 1
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
                    Repeater {
                        id: reminderValues
                        model: [-1 // ReminderNone
                               , 0 // ReminderTime
                               , 5 * 60 // Reminder5Min
                               , 15 * 60 // Reminder15Min
                               , 30 * 60 // Reminder30Min
                               , 60 * 60 // Reminder1Hour
                               , 2 * 60 * 60 // Reminder2Hour
                               , 6 * 60 * 60 // Reminder6Hour
                               , 12 * 60 * 60 // Reminder12Hour
                               , 24 * 60 * 60 // Reminder1Day
                               , 2 * 24 * 60 * 60 // Reminder2Day
                               ]
                        delegate: ReminderMenuItem { seconds: modelData }
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
                case CalendarEvent.RecurWeeklyByDays: recur.currentIndex = 2; recurringDays.days = event.recurWeeklyDays; break;
                case CalendarEvent.RecurWeekly: recur.currentIndex = 3; break;
                case CalendarEvent.RecurBiweekly: recur.currentIndex = 4; break;
                case CalendarEvent.RecurMonthly: recur.currentIndex = 5; break;
                case CalendarEvent.RecurMonthlyByDayOfWeek: recur.currentIndex = 6; break;
                case CalendarEvent.RecurMonthlyByLastDayOfWeek: recur.currentIndex = 7; break;
                case CalendarEvent.RecurYearly: recur.currentIndex = 8; break;
                case CalendarEvent.RecurCustom: recur.currentIndex = 9; recur.showCustom = true; break;
                }
            }

            reminder.setFromSeconds(event.reminder)
            recurEnd.recurEndDate = event.recurEndDate

            if (dialog._replaceOccurrence) {
                dateSelector.setStartDate(dialog.occurrence.startTimeInTz)
                dateSelector.setEndDate(dialog.occurrence.endTimeInTz)
            } else  {
                dateSelector.setStartDate(event.startTime)
                dateSelector.setEndDate(event.endTime)
            }
            timezone.set(event.startTimeSpec, event.startTimeZone)

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
        modification.recurWeeklyDays = recurringDays.days

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
            modification.setStartTime(dateSelector.startDate, timezone.timespec, timezone.name)
            modification.setEndTime(dateSelector.endDate, timezone.timespec, timezone.name)
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
