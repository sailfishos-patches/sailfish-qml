/****************************************************************************
**
** Copyright (C) 2015 - 2019 Jolla Ltd.
** Copyright (C) 2020 - 2021 Open Mobile Platform LLC.
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.TextLinking 1.0
import org.nemomobile.calendar 1.0
import Sailfish.Calendar 1.0 as Calendar
import Nemo.Notifications 1.0 as SystemNotifications

Column {
    id: root

    property QtObject event
    property QtObject occurrence
    property alias showDescription: descriptionText.visible
    property alias showHeader: eventHeader.visible
    property bool showSelector: !showHeader // by default, show calendar selector if colored header is not visible
    property bool cancellation

    signal eventRemovePressed

    function setAttendees(attendeeList) {
        attendees.model = attendeeList
    }

    width: parent.width
    visible: root.event
    spacing: Theme.paddingMedium

    Item {
        id: eventHeader
        height: displayLabel.height
        width: parent.width - 2*Theme.horizontalPageMargin
        x: Theme.horizontalPageMargin

        Rectangle {
            id: notebookRect
            width: Theme.paddingSmall
            radius: Math.round(width/3)
            color: root.event ? root.event.color : "transparent"
            height: parent.height
        }

        Label {
            id: displayLabel
            anchors {
                left: notebookRect.right
                leftMargin: Theme.paddingMedium
                right: parent.right
                rightMargin: Theme.paddingMedium
            }
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeLarge
            maximumLineCount: 5
            wrapMode: Text.Wrap
            text: Calendar.CalendarTexts.ensureEventTitle(root.event ? event.displayLabel : "")
            truncationMode: TruncationMode.Fade
        }
    }

    Item {
        height: timeColumn.height
        width: parent.width - 2*Theme.horizontalPageMargin
        x: Theme.horizontalPageMargin

        Column {
            id: timeColumn

            readonly property bool twoLineDates: !startDate.fitsOneLine || !endDate.fitsOneLine
            readonly property bool multiDay: {
                if (!root.occurrence) {
                    return false
                }

                var start = root.occurrence.startTime
                var end = root.occurrence.endTime
                return start.getFullYear() !== end.getFullYear()
                        || start.getMonth() !== end.getMonth()
                        || start.getDate() !== end.getDate()
            }

            width: parent.width - (recurrenceIcon.visible ? recurrenceIcon.width : 0)

            CalendarEventDate {
                id: startDate

                eventDate: root.occurrence ? root.occurrence.startTime : new Date(-1)
                showTime: parent.multiDay && (root.event && !root.event.allDay)
                timeContinued: parent.multiDay
                useTwoLines: timeColumn.twoLineDates
                cancelled: root.event && root.event.status == CalendarEvent.StatusCancelled
            }

            CalendarEventDate {
                id: endDate

                visible: parent.multiDay
                eventDate: root.occurrence ? root.occurrence.endTime : new Date(-1)
                showTime: root.event && !root.event.allDay
                useTwoLines: timeColumn.twoLineDates
                cancelled: root.event && root.event.status == CalendarEvent.StatusCancelled
            }

            Text {
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeMedium
                font.strikeout: root.event && root.event.status == CalendarEvent.StatusCancelled
                visible: !parent.multiDay
                //% "All day"
                text: root.event && root.occurrence ? (root.event.allDay ? qsTrId("sailfish_calendar-la-all_day")
                                                      : (Format.formatDate(root.occurrence.startTime, Formatter.TimeValue)
                                                         + " - "
                                                         + Format.formatDate(root.occurrence.endTime, Formatter.TimeValue))
                                    )
                                 : ""
            }

            Text {
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeMedium
                visible: recurrenceIcon.visible
                    && root.event && !isNaN(root.event.recurEndDate.getTime())
                //: %1 is a localized date string, giving the end of the recurring series.
                //% "Until %1"
                text: root.event ? qsTrId("sailfish_calendar-la-recurrence_end").arg(Qt.formatDate(root.event.recurEndDate)) : ""
            }

            Text {
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeMedium
                visible: root.event && root.event.status == CalendarEvent.StatusCancelled
                //% "The event is cancelled."
                text: qsTrId("sailfish_calendar-la-event-cancelled")
            }
        }
        Image {
            id: recurrenceIcon
            visible: root.event && root.event.recur !== CalendarEvent.RecurOnce
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            source: "image://theme/icon-s-sync?" + Theme.highlightColor
        }
    }

    Item {
        // reminderRow
        width: parent.width - 2*Theme.horizontalPageMargin
        height: reminderText.height
        x: Theme.horizontalPageMargin
        visible: root.event && (root.event.reminder >= 0 || !isNaN(root.event.reminderDateTime.getTime()))

        Label {
            id: reminderText
            width: parent.width - reminderIcon.width
            anchors.left: parent.left
            color: Theme.highlightColor
            wrapMode: Text.Wrap
            text: {
                if (root.event && root.event.reminder >= 0) {
                    //: %1 gets replaced with reminder time, e.g. "15 minutes before"
                    //% "Reminder %1"
                    return qsTrId("sailfish_calendar-view-reminder")
                        .arg(Calendar.CalendarTexts.getReminderText(root.event.reminder,
                             root.event.allDay ? root.event.startTime : undefined))
                } else if (root.event && !isNaN(root.event.reminderDateTime.getTime())) {
                    //: %1 is replaced by the date in format like Monday 2nd November 2020
                    //: %2 is replaced by the time.
                    //% "Reminder %1, %2"
                    return qsTrId("sailfish_calendar-view-reminder-date-time")
                               .arg(Format.formatDate(event.reminderDateTime, Format.DateFull))
                               .arg(Format.formatDate(event.reminderDateTime, Format.TimeValue))
                } else {
                    return ""
                }
            }
        }
        Image {
            id: reminderIcon
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
            }
            source: "image://theme/icon-s-alarm?" + Theme.highlightColor
        }
    }

    BackgroundItem {
        // locationRow
        visible: root.event && root.event.location !== ""
        width: parent.width - 2*Theme.horizontalPageMargin
        height: Math.max(locationIcon.height, locationText.height)
        x: Theme.horizontalPageMargin
        onClicked: Qt.openUrlExternally("geo:?q=" + encodeURIComponent(locationText.text))

        Image {
            id: locationIcon
            source: "image://theme/icon-m-location"
        }

        Label {
            id: locationText

            width: parent.width - locationIcon.width - Theme.paddingMedium
            height: contentHeight
            x: locationIcon.width + Theme.paddingMedium
            anchors.top: lineCount > 1 ? parent.top : undefined
            anchors.verticalCenter: lineCount > 1 ? undefined : locationIcon.verticalCenter
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.Wrap
            text: root.event ? root.event.location : ""
        }
    }

    Column {
        // attendeeColumn
        width: parent.width
        spacing: Theme.paddingMedium

        Loader {
            active: cancellation
            width: parent.width
            sourceComponent: CalendarEventRemove {
                readOnly: !event || root.event.readOnly
                onEventRemovePressed: root.eventRemovePressed()
            }
        }

        Loader {
            active: event && event.rsvp && !cancellation
            width: parent.width
            sourceComponent: Item {
                width: parent.width
                height: responseButtons.height + responseButtons.anchors.topMargin + Theme.paddingMedium
                InvitationResponseButtons {
                    id: responseButtons
                    width: parent.width
                    anchors.top: parent.top
                    anchors.topMargin: Theme.paddingMedium
                    responseState: event ? event.ownerStatus : CalendarEvent.ResponseUnspecified
                    enabled: !disableTimer.running
                    onResponseStateChanged: {
                        disableTimer.stop()
                    }

                    onCalendarInvitationResponded: {
                        var res = root.event.sendResponse(response)
                        disableTimer.start()
                        if (!res) {
                            var previewText
                            switch (response) {
                            case CalendarEvent.ResponseAccept:
                                //: Failed to send invitation response (accept)
                                //% "Failed to accept invitation"
                                previewText = qsTrId("sailfish_calendar-la-response_failed_body_accept")
                                break
                            case CalendarEvent.ResponseTentative:
                                //: Failed to send invitation response (tentative)
                                //% "Failed to tentatively accept invitation"
                                previewText = qsTrId("sailfish_calendar-la-response_failed_body_tentative")
                                break
                            case CalendarEvent.ResponseDecline:
                                //: Failed to send invitation response (decline)
                                //% "Failed to decline invitation"
                                previewText = qsTrId("sailfish_calendar-la-la-response_failed_body_decline")
                                break
                            default:
                                break
                            }
                            if (previewText.length > 0) {
                                systemNotification.body = previewText
                                systemNotification.publish()
                            }
                        }
                    }
                }
                Timer {
                    id: disableTimer
                    interval: 5000
                    repeat: false
                }
                SystemNotifications.Notification {
                    id: systemNotification

                    appIcon: "icon-lock-calendar"
                    isTransient: true
                }
            }
        }

        Column {
            id: attendees

            property var model: []

            width: parent.width
            visible: model.length > 0

            Row {
                width: parent.width - 2*x
                x: Theme.horizontalPageMargin
                height: Theme.itemSizeSmall

                spacing: Theme.paddingMedium

                Image {
                    id: attendeeIcon
                    anchors.verticalCenter: parent.verticalCenter
                    source: "image://theme/icon-m-people"
                }
                Label {
                    id: attendeesLabel

                    anchors.verticalCenter: parent.verticalCenter

                    //% "%n people"
                    text: qsTrId("sailfish_calendar-la-people_count", attendees.model.length)
                    color: palette.highlightColor
                }
            }

            Repeater {
                model: attendees.model.slice(0, 5)

                delegate: CalendarAttendeeDelegate {
                    id: attendeeItem

                    leftMargin: Theme.horizontalPageMargin + attendeesLabel.x
                    name: modelData.name
                    email: modelData.email
                    secondaryText: {
                        if (modelData.isOrganizer) {
                            //% "Organizer"
                            return qsTrId("sailfish-calendar-la-event_organizer_attendee")
                        } else if (modelData.participationRole === Person.OptionalParticipant) {
                            //% "Optional"
                            return qsTrId("sailfish-calendar-la-event_optional_attendee")
                        } else {
                            return ""
                        }
                    }
                    participationStatus: modelData.participationStatus
                }
            }

            BackgroundItem {
                height: Theme.itemSizeSmall

                visible: attendees.model.length > 5

                onClicked: {
                    pageStack.push("CalendarAttendeeViewPage.qml",
                                   { attendeeList: attendees.model })
                }

                Label {
                    x: Theme.horizontalPageMargin + attendeesLabel.x
                    y: (parent.height - height) / 2

                    //% "Show more..."
                    text: qsTrId("sailfish_calendar-la-show_more")
                }

                Icon {
                    x: parent.width - width - Theme.horizontalPageMargin
                    y: (parent.height - height) / 2

                    source: "image://theme/icon-m-right"
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: Theme.paddingMedium

        SectionHeader {
            visible: syncWarning.visible
            //% "Sync status"
            text: qsTrId("sailfish_calendar-he-event_sync_status")
        }

        SyncWarningItem {
            id: syncWarning
            width: parent.width - 2 * Theme.horizontalPageMargin
            x: Theme.horizontalPageMargin
            visible: syncFailure != CalendarEvent.NoSyncFailure
            syncFailure: root.event ? root.event.syncFailure : CalendarEvent.NoSyncFailure
            color: Theme.errorColor
        }

        SyncFailureResolver {
            event: root.event
            visible: syncWarning.visible
        }

        SectionHeader {
            visible: descriptionText.visible && descriptionText.text != ""
            //% "Description"
            text: qsTrId("sailfish_calendar-he-event_description")
        }

        LinkedText {
            id: descriptionText

            width: parent.width - 2*Theme.horizontalPageMargin
            x: Theme.horizontalPageMargin
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.Wrap
            plainText: root.event ? root.event.description : ""
        }
    }

    CalendarSelector {
        name: query.isValid ? query.name : ""
        localCalendar: query.localCalendar
        description: query.isValid ? query.description : ""
        color: query.isValid ? query.color : "transparent"
        accountIcon: query.isValid ? query.accountIcon : ""
        enabled: false
        opacity: 1.0
        visible: showSelector
        NotebookQuery {
            id: query
            targetUid: (root.event && root.event.calendarUid) ? root.event.calendarUid : ""
        }
    }
}

