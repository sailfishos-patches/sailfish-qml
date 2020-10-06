/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
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

    property bool open: true

    property alias contentX: content.x
    readonly property alias contentY: header.height

    property alias contentItem: buttonsColumn
    property alias heightBehaviorEnabled: heightBehavior.enabled

    property QtObject event
    property QtObject occurrence

    readonly property bool inlineInvitation: email && email.calendarInvitationSupportsEmailResponses

    signal loadImagesClicked
    signal loadImagesCloseClicked

    signal clicked

    function _emailRecipients() {
        var recipientsDisplayName = email.recipientsDisplayName.toString()
        return recipientsDisplayName != ""
                ? //: 'To: ' message recipients (keep the colon separator here)
                  //% "To: %1"
                  qsTrId("jolla-email-la-recipients_header").arg(recipientsDisplayName)
                : //% "No recipients"
                  qsTrId("jolla-email-la-no_recipient")
    }

    BackgroundItem {
        id: headerBackground

        width: root.width
        height: header.height

        onClicked: root.clicked()

        SilicaControl {
            width: headerBackground.width
            height: header.height

            highlighted: undefined

            palette {
                primaryColor: headerBackground.palette.highlightColor
                secondaryColor: headerBackground.palette.secondaryHighlightColor
                highlightColor: headerBackground.palette.primaryColor
                secondaryHighlightColor: headerBackground.palette.secondaryColor
            }

            PageHeader {
                id: header

                title: email ? (isOutgoing ? _emailRecipients() : email.fromDisplayName) : ""
                description: email ? email.subject : ""
                _titleItem.anchors.right: sensitivityImage.visible
                                          ? sensitivityImage.left
                                          : (priorityImage.visible ? priorityImage.left : header.right)
                _titleItem.anchors.rightMargin: (priorityImage.visible || sensitivityImage.visible)
                                                    ? Theme.paddingSmall : Theme.horizontalPageMargin
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

                Image {
                    id: priorityImage
                    visible: source != ""
                    anchors {
                        verticalCenter: header._titleItem.verticalCenter
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
                        verticalCenter: header._titleItem.verticalCenter
                        verticalCenterOffset: Theme.paddingSmall / 2
                        right: priorityImage.visible ? priorityImage.left : parent.right
                        rightMargin: priorityImage.visible ? Theme.paddingSmall : Theme.horizontalPageMargin
                    }
                    source: visible ? "image://theme/icon-s-secure" : ""
                }
            }
        }
    }

    SilicaControl {
        id: content

        palette.colorScheme: Theme.DarkOnLight

        width: root.width - x
        height: root.open ? buttonsColumn.implicitHeight : 0

        clip: heightAnimation.running
        visible: root.open || heightAnimation.running

        Behavior on height {
            id: heightBehavior
            SmoothedAnimation { id: heightAnimation; easing.type: Easing.InOutQuad; duration: 100 }
        }

        Rectangle {
            width: root.width
            height: buttonsColumn.implicitHeight

            color: "#f3f0f0"
        }

        Column {
            id: buttonsColumn
            width: parent.width

            LoadImagesItem {
                width: root.width

                visible: root.showLoadImages

                onClicked: root.loadImagesClicked()
                onCloseClicked: root.loadImagesCloseClicked()
            }

            AttachmentRow {
                width: root.width

                visible: email && email.numberOfAttachments > 0
                attachmentsModel: root.attachmentsModel
                emailMessage: email
            }

            Loader {
                visible: email && email.signatureStatus != EmailMessage.NoDigitalSignature
                // SignatureItem.qml is not installed by default.
                active: root.email && emailAppCryptoEnabled
                source: "SignatureItem.qml"
                onItemChanged: if (item) item.email = root.email
                width: parent.width
            }

            CalendarDelegate {
                width: root.width

                visible: email && email.hasCalendarInvitation && !inlineInvitation
                email: root.email
            }
        }
    }
}
