/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1
import org.nemomobile.calendar 1.0
import Sailfish.TextLinking 1.0

Page {
    id: root

    property EmailMessage message
    readonly property var messageToAddresses: message ? message.to : []
    readonly property var messageCcAddresses: message ? message.cc : []
    property QtObject calendarEvent
    property bool isLocalFile

    ImportModel {
        icsString: message && message.calendarInvitationSupportsEmailResponses
                   ? message.calendarInvitationBody : ""
        onCountChanged: {
            if (count > 0) {
                root.calendarEvent = getEvent(0)
            } else {
                root.calendarEvent = null
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        Column {
            id: content

            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                //: Message info header
                //% "Message info"
                title: qsTrId("jolla-email-he-message_info")
            }

            MessageInfoLabel {
                text: message ? message.subject : ""
                font.pixelSize: Theme.fontSizeMedium
                maximumLineCount: 10
            }

            Column {
                width: parent.width

                LinkedText {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x
                    plainText: message ? (message.fromAddress != "" ? message.fromDisplayName + " <" + message.fromAddress + ">"
                                                                    : message.fromDisplayName) : ""
                    font.pixelSize: Theme.fontSizeSmall
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap
                }

                MessageInfoLabel {
                    text: message ? Format.formatDate(message.date, Formatter.Timepoint) : ""
                }
            }

            MessageInfoSection {
                visible: calendarEvent !== null
                //: Start and end time of a meeting
                //% "When:"
                headerText: qsTrId("jolla-email-la-cal-when")
                bodyText: calendarEvent ? (Format.formatDate(
                                               calendarEvent.startTime, Formatter.Timepoint) +
                                           " - " +
                                           Format.formatDate(
                                               calendarEvent.endTime, Formatter.Timepoint)) : ""
            }

            MessageInfoLinkedText {
               visible: calendarEvent && calendarEvent.organizer != ""
                //: Meeting invitation organizer address
                //% "Organizer:"
                headerText: qsTrId("jolla-email-la-cal-organizer")
                plainText: calendarEvent ? calendarEvent.organizer : ""
            }

            MessageInfoLinkedText {
                visible: message && message.replyTo != ""
                //: Reply to address
                //% "Reply to:"
                headerText: qsTrId("jolla-email-la-replyTo")
                plainText: message ? message.replyTo : ""
            }

            MessageInfoRepeater {
                visible: messageToAddresses != ""
                headerText: {
                    if (calendarEvent) {
                        //: 'Mandatory: ' recipients label for calendar invitation
                        //% "Mandatory:"
                        return qsTrId("jolla-email-la-cal-mandatory_info")
                    } else {
                        //: 'To: ' recipients label
                        //% "To:"
                        return qsTrId("jolla-email-la-to_info")
                    }
                }
                model: messageToAddresses
            }

            MessageInfoRepeater {
                visible: messageCcAddresses != ""
                headerText: {
                    if (calendarEvent) {
                        //: 'Optional: ' recipients label for calendar invitation
                        //% "Optional:"
                        return qsTrId("jolla-email-la-cal-optional_info")
                    } else {
                        //: 'Cc: ' recipients label
                        //% "Cc:"
                        return qsTrId("jolla-email-la-cc_info")
                    }
                }
                model: messageCcAddresses
            }

            MessageInfoSection {
                //: 'Importance: ' label
                //% "Importance:"
                headerText: qsTrId("jolla-email-la-importance")
                bodyText: message ? priorityText(message.priority) : ""
                function priorityText(priority) {
                    if (priority === EmailMessageListModel.HighPriority) {
                        //: Message priority high
                        //% "High"
                        return qsTrId("jolla-email-la-priority_high")
                    } else if (priority === EmailMessageListModel.LowPriority) {
                        //: Message priority low
                        //% "Low"
                        return qsTrId("jolla-email-la-priority_low")
                    } else {
                        //: Message priority normal
                        //% "Normal"
                        return qsTrId("jolla-email-la-priority_Normal")
                    }
                }
            }

            MessageInfoSection {
                visible: calendarEvent
                //: 'Secrecy: ' label for calendar invitation
                //% "Secrecy:"
                headerText: qsTrId("jolla-email-la-cal-secrecy")
                bodyText: secrecyText(calendarEvent ? calendarEvent.secrecy : CalendarEvent.SecrecyPublic)
                function secrecyText(secrecy) {
                    switch (secrecy) {
                    case CalendarEvent.SecrecyPrivate:
                        //: Invitation secrecy private
                        //% "Private"
                        return qsTrId("jolla-email-la-cal-secrecy_private")
                    case CalendarEvent.SecrecyConfidential:
                        //: Invitation secrecy confidential
                        //% "Confidential"
                        return qsTrId("jolla-email-la-cal-secrecy_confidential")
                    default:
                        //: Invitation secrecy public
                        //% "Public"
                        return qsTrId("jolla-email-la-cal-secrecy_public")
                    }
                }
            }

            MessageInfoSection {
                visible: calendarEvent
                //: 'Repeat: ' label for calendar
                //% "Repeat:"
                headerText: qsTrId("jolla-email-la-cal-repeat")
                bodyText: recurText(calendarEvent ? calendarEvent.recur : CalendarEvent.RecurOnce)

                function recurText(recur) {
                    if (calendarEvent) {
                        switch (calendarEvent.recur) {
                        case CalendarEvent.RecurDaily:
                            //% "Every Day"
                            return qsTrId("jolla-email-la-cal-recurrence-every_day")
                        case CalendarEvent.RecurWeekly:
                            //% "Every Week"
                            return qsTrId("jolla-email-la-cal-recurrence-every_week")
                        case CalendarEvent.RecurBiweekly:
                            //% "Every 2 Weeks"
                            return qsTrId("jolla-email-la-cal-recurrence-every_2_weeks")
                        case CalendarEvent.RecurMonthly:
                            //% "Every Month"
                            return qsTrId("jolla-email-la-cal-recurrence-every_month")
                        case CalendarEvent.RecurYearly:
                            //% "Every Year"
                            return qsTrId("jolla-email-la-cal-recurrence-every_year")
                        case CalendarEvent.RecurCustom:
                            //% "Custom"
                            return qsTrId("jolla-email-la-cal-recurrence-custom")
                        }
                    }
                    //: Recurrence - not set (once) text
                    //% "Once"
                    return qsTrId("jolla-email-la-cal-recurrence-once")
                }
            }

            MessageInfoSection {
                //: 'Account: ' label
                //% "Account:"
                headerText: qsTrId("jolla-email-la-account")
                bodyText: message ? mailAccountListModel.displayNameFromAccountId(message.accountId) : ""
                visible: message && mailAccountListModel.indexFromAccountId(message.accountId) >= 0
            }

            MessageInfoSection {
                //: Message 'Size: ' label
                //% "Size:"
                headerText: qsTrId("jolla-email-la-message_size")
                bodyText: Format.formatFileSize(message ? message.size : 0)
                visible: !isLocalFile
            }
        }

        VerticalScrollDecorator {}
    }
}
