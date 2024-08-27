/*
 * Copyright (c) 2015 - 2019 Jolla Ltd.
 * Copyright (c) 2020 - 2021 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1
import org.nemomobile.calendar 1.0

BackgroundItem {
    id: root

    property EmailMessage email
    property real leftMargin: Theme.paddingMedium
    property real rightMargin: Theme.paddingMedium
    property real iconSize: Theme.iconSizeMedium

    contentHeight: Theme.itemSizeExtraSmall
    height: contentItem.height

    InvitationQuery {
        id: invitationQuery
        invitationFile: !!email ? email.calendarInvitationUrl : ""
        property bool triggerInvitationWhenFinished
        onQueryFinished: {
            if (triggerInvitationWhenFinished) {
                triggerInvitation()
            }
        }
        function triggerInvitation() {
            invitationQuery.triggerInvitationWhenFinished = false
            if (invitationQuery.instanceId.length > 0 && invitationQuery.startTime.length > 0) {
                // the invitation has already been synced or imported.
                var obj = pageStack.animatorPush(Qt.resolvedUrl("CalendarEventPage.qml"), {
                                                     instanceId: invitationQuery.instanceId,
                                                     startTime: invitationQuery.startTime,
                                                     cancellation: email.hasCalendarCancellation
                                                 })
                obj.pageCompleted.connect(function(page) {
                    page.eventRemovePressed.connect(function() {
                        invitationQuery.query()
                    })
                })
            } else {
                // the invitation doesn't yet exist in the calendar.
                pageStack.animatorPush(Qt.resolvedUrl("CalendarEventPreviewPage.qml"), {
                                           icsString: email.calendarInvitationBody,
                                           cancellation: email.hasCalendarCancellation
                                       })
            }
        }
    }

    onClicked: {
        if ((email.calendarInvitationStatus != EmailMessage.Downloading
             && email.calendarInvitationStatus != EmailMessage.Downloaded
             && email.calendarInvitationStatus != EmailMessage.Saved)
                || email.calendarInvitationUrl === "") {
            email.getCalendarInvitation()
        } else if (invitationQuery.busy) {
            invitationQuery.triggerInvitationWhenFinished = true
        } else {
            invitationQuery.triggerInvitation()
        }
    }

    Icon {
        id: defaultIcon
        x: leftMargin
        height: iconSize
        width: height
        anchors.verticalCenter: parent.verticalCenter
        sourceSize.width: width
        sourceSize.height: height
        source: email.hasCalendarInvitation
                ? "image://theme/icon-l-date"
                : "image://theme/icon-l-calendar-cancelled"
    }

    Item {
        anchors {
            verticalCenter: parent.verticalCenter
            left: defaultIcon.right
            leftMargin: Theme.paddingMedium
            right: parent.right
            rightMargin: root.rightMargin
        }

        height: calendarInvitationLabel.height + statusLabel.height

        Label {
            id: calendarInvitationLabel
            width: parent.width
            font.pixelSize: Theme.fontSizeExtraSmall
            text: email.hasCalendarInvitation
                    //: Calendar invitation label
                    //% "Calendar invitation"
                  ? qsTrId("jolla-email-la-calendar_invitation")
                    //: Calendar cancellation label
                    //% "Calendar cancellation"
                  : qsTrId("jolla-email-la-calendar_cancellation")
            truncationMode: TruncationMode.Fade
        }

        Label {
            id: statusLabel
            visible: email && email.calendarInvitationStatus != EmailMessage.Downloading
            width: parent.width
            anchors.top: calendarInvitationLabel.bottom
            font.pixelSize: Theme.fontSizeTiny

            text: email ? statusText(email.calendarInvitationStatus) : ""
            truncationMode: TruncationMode.Fade
        }

        ProgressBar {
            visible: email && email.calendarInvitationStatus === EmailMessage.Downloading
            indeterminate: true
            width: parent.width
            leftMargin: Theme.paddingMedium
            rightMargin: Theme.paddingMedium
            anchors.top: calendarInvitationLabel.bottom
            highlighted: root.highlighted
        }
    }

    function statusText(status) {
        if (status === EmailMessage.Unknown) {
            //: Calendar invitation download state - Not Downloaded
            //% "Not Downloaded"
            return qsTrId("jolla-email-la-calendar_invitation_not_downloaded")
        } else if (status === EmailMessage.Downloaded || status === EmailMessage.Saved) {
            //: Calendar invitation download state - Downloaded
            //% "Downloaded"
            return qsTrId("jolla-email-la-calendar_invitation_downloaded")
        } else if (status === EmailMessage.Downloading) {
            //: Calendar invitation download state - Downloading
            //% "Downloading"
            return qsTrId("jolla-email-la-calendar_invitation_downloading")
        } else if (status === EmailMessage.Failed) {
            //: Calendar invitation download state - Failed
            //% "Failed"
            return qsTrId("jolla-email-la-calendar_invitation_failed")
        } else if (status === EmailMessage.FailedToSave) {
            //: Calendar invitation - Failed to save file
            //% "Failed to save file"
            return qsTrId("jolla-email-la-calendar_invitation_failed_save")
        } else {
            return ""
        }
    }
}
