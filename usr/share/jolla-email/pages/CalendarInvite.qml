/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Calendar 1.0
import Nemo.Email 0.1
import org.nemomobile.calendar 1.0

SilicaControl {
    id: invite

    property QtObject event
    property QtObject occurrence
    property alias preferredButtonWidth: responseButtons.preferredButtonWidth

    property int pixelSize: Theme.fontSizeSmall

    readonly property bool twoLineDates: !startDate.fitsOneLine || (multiDay && !endDate.fitsOneLine)
    readonly property bool multiDay: {
        if (!invite.occurrence) {
            return false
        }

        var start = invite.occurrence.startTime
        var end = invite.occurrence.endTime
        return start.getFullYear() !== end.getFullYear()
                || start.getMonth() !== end.getMonth()
                || start.getDate() !== end.getDate()
    }


    implicitHeight: timesFlow.height + responseButtons.implicitHeight + Theme.paddingLarge
    palette.colorScheme: Theme.DarkOnLight

    Rectangle {
        width: invite.width
        height: invite.height

        color: "#f3f0f0"
    }

    // Ideally put these side by side aligned to each end but if there's not enough space break over
    // two lines and left align.
    Flow {
        id: timesFlow

        x: Theme.horizontalPageMargin

        width: invite.width - (2 * x)

        spacing: Math.max(Theme.paddingSmall, width - startDate.width - endDateOrDuration.width)

        CalendarEventDate {
            id: startDate

            eventDate: invite.occurrence ? invite.occurrence.startTime : new Date(-1)
            showTime: invite.multiDay && (invite.event && !invite.event.allDay)
            timeContinued: invite.multiDay
            useTwoLines: invite.twoLineDates
            color: invite.palette.highlightColor
            font.pixelSize: invite.pixelSize
            maximumWidth: timesFlow.width / (invite.multiDay ? 2 : 1)
        }

        Row {
            id: endDateOrDuration

            CalendarEventDate {
                id: endDate

                visible: invite.multiDay
                eventDate: invite.occurrence ? invite.occurrence.endTime : new Date(-1)
                showTime: invite.event && !invite.event.allDay
                useTwoLines: invite.twoLineDates
                color: invite.palette.highlightColor
                font.pixelSize: invite.pixelSize
                maximumWidth: timesFlow.width / 2
            }

            Text {
                height: startDate.height

                color: invite.palette.highlightColor
                font.pixelSize: invite.pixelSize
                visible: !invite.multiDay
                verticalAlignment: Text.AlignVCenter

                //% "All day"
                text: !invite.event ? "" : (invite.event.allDay
                        ? qsTrId("jolla-email-la-all_day")
                        : (Format.formatDate(invite.occurrence.startTime, Formatter.TimeValue)
                            + " - "
                            + Format.formatDate(invite.occurrence.endTime, Formatter.TimeValue)))
            }
        }
    }

    InvitationResponseButtons {
        id: responseButtons

        y: timesFlow.height + Math.min(Theme.paddingLarge, (invite.height - timesFlow.height - height - Theme.paddingMedium) / 2)

        subject: invite.event ? invite.event.displayLabel : ""
        width: parent.width
        labelFont.pixelSize: invite.pixelSize
        _backgroundColor: "white"
        onCalendarInvitationResponded: {
            var emailResponse = EmailAgent.InvitationResponseUnspecified
            switch (response) {
            case CalendarEvent.ResponseAccept:
                emailResponse = EmailAgent.InvitationResponseAccept
                break
            case CalendarEvent.ResponseTentative:
                emailResponse = EmailAgent.InvitationResponseTentative
                break
            case CalendarEvent.ResponseDecline:
                emailResponse = EmailAgent.InvitationResponseDecline
                break
            default:
                return
            }
            emailAgent.respondToCalendarInvitation(email.messageId, emailResponse, responseSubject)
            pageStack.pop()
        }
    }
}
