/****************************************************************************
**
** Copyright (C) 2015 - 2019 Jolla Ltd.
** Copyright (C) 2020 Open Mobile Platform LLC.
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.TextLinking 1.0
import org.nemomobile.calendar 1.0
import Sailfish.Calendar 1.0 as Calendar
import org.nemomobile.notifications 1.0 as SystemNotifications

Column {
    id: root

    property QtObject event
    property QtObject occurrence
    property alias showDescription: descriptionText.visible
    property alias showHeader: eventHeader.visible
    property bool showSelector: !showHeader // by default, show calendar selector if colored header is not visible

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
            text: root.event ? root.event.displayLabel : ""
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
            }

            CalendarEventDate {
                id: endDate

                visible: parent.multiDay
                eventDate: root.occurrence ? root.occurrence.endTime : new Date(-1)
                showTime: root.event && !root.event.allDay
                useTwoLines: timeColumn.twoLineDates
            }

            Text {
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeMedium
                visible: !parent.multiDay
                //% "All day"
                text: root.event ? (root.event.allDay ? qsTrId("sailfish_calendar-la-all_day")
                                                      : (Format.formatDate(root.occurrence.startTime, Formatter.TimeValue)
                                                         + " - "
                                                         + Format.formatDate(root.occurrence.endTime, Formatter.TimeValue))
                                    )
                                 : ""
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
        visible: root.event && root.event.reminder >= 0

        Label {
            id: reminderText
            width: parent.width - reminderIcon.width
            anchors.left: parent.left
            color: Theme.highlightColor
            wrapMode: Text.Wrap
            //: %1 gets replaced with reminder time, e.g. "15 minutes before"
            //% "Reminder %1"
            text: root.event ? qsTrId("sailfish_calendar-view-reminder")
                               .arg(Calendar.CommonCalendarTranslations.getReminderText(root.event.reminder))
                             : ""
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

    Column {
        width: parent.width
        spacing: Theme.paddingMedium

        Item {
            visible: root.event && root.event.location !== ""
            width: parent.width - 2*Theme.horizontalPageMargin
            height: Math.max(locationIcon.height, locationText.height)
            x: Theme.horizontalPageMargin

            Image {
                id: locationIcon
                source: "image://theme/icon-m-location"
            }

            Label {
                id: locationText

                width: parent.width - locationIcon.width
                height: contentHeight
                x: locationIcon.width
                anchors.top: lineCount > 1 ? parent.top : undefined
                anchors.verticalCenter: lineCount > 1 ? undefined : locationIcon.verticalCenter
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.Wrap
                text: root.event ? root.event.location : ""
            }
        }

        Loader {
            active: event && event.rsvp
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

            width: parent.width - 2*x
            x: Theme.horizontalPageMargin
            visible: model.length > 0

            Row {
                width: parent.width
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

                    x: attendeesLabel.x
                    width: parent.width - x - Theme.horizontalPageMargin

                    name: modelData.name
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
                    nameColor: palette.highlightColor
                }
            }

            BackgroundItem {
                x: -attendees.x
                width: root.width
                height: Theme.itemSizeSmall

                visible: attendees.model.length > 5

                onClicked: {
                    pageStack.push("CalendarAttendeeViewPage.qml",
                                   { attendeeList: attendees.model })
                }

                Label {
                    x: attendeesLabel.x + attendees.x
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

