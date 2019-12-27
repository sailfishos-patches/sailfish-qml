/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Calendar 1.0
import Nemo.Email 0.1
import org.nemomobile.calendar 1.0
import "utils.js" as Utils

Column {
    id: root

    property EmailMessage email
    property AttachmentListModel attachmentsModel
    property bool portrait
    property bool showLoadImages
    property bool isOutgoing

    property QtObject event
    property QtObject occurrence

    readonly property bool inlineInvitation: email && email.calendarInvitationSupportsEmailResponses

    signal loadImagesClicked

    spacing: Theme.paddingMedium

    function _emailRecipients() {
        var recipientsDisplayName = email.recipientsDisplayName.toString()
        return recipientsDisplayName != ""
                ? //: 'To: ' message recipients (keep the colon separator here)
                  //% "To: %1"
                  qsTrId("jolla-email-la-recipients_header").arg(recipientsDisplayName)
                : //% "No recipients"
                  qsTrId("jolla-email-la-no_recipient")
    }

    PageHeader {
        id: pageHeader

        title: email ? (isOutgoing ? _emailRecipients() : email.fromDisplayName) : ""
        _titleItem.anchors.right: sensitivityImage.visible
                                  ? sensitivityImage.left
                                  : (priorityImage.visible ? priorityImage.left : pageHeader.right)
        _titleItem.anchors.rightMargin: (priorityImage.visible || sensitivityImage.visible)
                                        ? Theme.paddingSmall : Theme.horizontalPageMargin
        Image {
            id: priorityImage
            visible: source != ""
            anchors {
                verticalCenter: pageHeader._titleItem.verticalCenter
                verticalCenterOffset: Theme.paddingSmall / 2
                right: parent.right
                rightMargin: Theme.horizontalPageMargin - Theme.paddingMedium
            }
            source: email ? Utils.priorityIcon(email.priority) : ""
        }
        Image {
            id: sensitivityImage
            visible: inlineInvitation && event &&
                     (event.secrecy === CalendarEvent.SecrecyPrivate ||
                      event.secrecy === CalendarEvent.SecrecyConfidential)
            anchors {
                verticalCenter: pageHeader._titleItem.verticalCenter
                verticalCenterOffset: Theme.paddingSmall / 2
                right: priorityImage.visible ? priorityImage.left : parent.right
                rightMargin: priorityImage.visible ? Theme.paddingSmall : Theme.horizontalPageMargin
            }
            source: visible ? "image://theme/icon-s-secure" : ""
        }
    }

    ImportModel {
        icsString: inlineInvitation ? email.calendarInvitationBody : ""
        onCountChanged: {
            if (count > 0) {
                root.event = getEvent(0)
                root.occurrence = root.event ? root.event.nextOccurrence() : null
            } else {
                root.event = null
                root.occurrence = null
            }
        }
    }

    Loader {
        active: inlineInvitation && root.event != null
        width: parent.width
        sourceComponent: CalendarEventView {
            event: root.event
            occurrence: root.occurrence
            showDescription: false
            onEventChanged: {
                if (event && event.organizerEmail !== email.fromAddress
                        && event.organizerEmail.length > 0
                        && event.organizer.length > 0) {
                    var organizerAsList =
                            [
                                { isOrganizer: true, name: event.organizer }
                            ];
                    setAttendees(organizerAsList)
                }
            }
        }
    }

    Column {
        width: parent.width
        AttachmentRow {
            width: parent.width
            visible: email && email.numberOfAttachments > 0
            attachmentsModel: root.attachmentsModel
            emailMessage: email
        }

        CalendarDelegate {
            visible: email && email.hasCalendarInvitation && !inlineInvitation
            email: root.email
        }

        Loader {
            visible: email && email.signatureStatus != EmailMessage.NoDigitalSignature
            // SignatureItem.qml is not installed by default.
            active: root.email && emailAppCryptoEnabled
            source: "SignatureItem.qml"
            onItemChanged: if (item) item.email = root.email
            width: parent.width
        }
    }

    LoadImagesItem {
        visible: showLoadImages
        onClicked: loadImagesClicked()
    }

    InvitationResponseButtons {
        subject: root.event ? root.event.displayLabel : ""
        width: parent.width
        visible: inlineInvitation
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

    Item {
        width: parent.width
        height: 1
        visible: inlineInvitation
    }
}
