/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1
import com.jolla.email 1.1
import "utils.js" as Utils

ListItem {
    id: messageItem

    property bool selectMode
    property bool showRecipientsName
    property alias primaryLine: senderName.text
    property alias secondaryLine: subjectText.text
    property alias date: msgDateTime.text
    property bool isDraftsFolder
    property string searchString
    property bool highlightSender
    property bool highlightRecipients
    property bool highlightSubject
    property bool highlightBody

    signal emailViewerRequested(int messageId)

    function remove() {
        BatchedMessageDeletion.addMessage(model.messageId)

        var remorseItem = remorseDelete(function() {
            animateRemoval()
            BatchedMessageDeletion.messageReadyForDeletion(model.messageId)
            BatchedMessageDeletion.run(emailAgent)
        })
        remorseItem.canceled.connect(function() {
            BatchedMessageDeletion.removeMessage(model.messageId)
        })
    }

    onClicked: {
        if (!selectMode) {
            if (isDraftsFolder) {
                pageStack.animatorPush(Qt.resolvedUrl("ComposerPage.qml"),
                                       { messageId: model.messageId,
                                         originalMessageId: model.messageId,
                                         draft: true,
                                         draftRemoveCallback: remove })
            } else {
                emailViewerRequested(model.messageId)
            }
        }
    }

    contentHeight: content.height + content.y + Theme.paddingMedium
    menu: contextMenuComponent
    highlighted: menuOpen || down || (model.selected && selectMode)

    GlassItem {
        visible: !model.readStatus
        width: Theme.itemSizeSmall
        height: Theme.itemSizeSmall
        anchors.horizontalCenter: parent.left
        y: content.y + senderName.height/2 - height/2
        radius: 0.14
        falloffRadius: 0.13
        color: Theme.highlightColor
    }

    Column {
        id: content
        y: Theme.paddingMedium
        spacing: -Math.round(Theme.paddingSmall/2)
        anchors {
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
        }
        Item {
            height: senderName.height
            width: parent.width
            Label {
                id: senderName

                text: showRecipientsName
                      ? (model.recipientsDisplayName.toString() != ""
                         ? Theme.highlightText(model.recipientsDisplayName.toString(),
                                               (highlightRecipients ? searchString : ""),
                                               Theme.highlightColor)
                         : //% "No recipients"
                           qsTrId("jolla-email-la-no_recipient"))
                      : Theme.highlightText(model.senderDisplayName, (highlightSender ? searchString : ""), Theme.highlightColor)
                textFormat: Text.StyledText
                anchors {
                    left: parent.left
                    right: msgDateTime.left
                    rightMargin: Theme.paddingLarge
                }
                truncationMode: TruncationMode.Fade
            }

            Label {
                id: msgDateTime
                text: Format.formatDate(model.qDateTime, Formatter.TimeValue)
                font.pixelSize: Theme.fontSizeExtraSmall
                anchors {
                    right: parent.right
                    baseline: senderName.baseline
                }
            }
            Row {
                id: icons
                spacing: Theme.paddingSmall
                anchors {
                    top: senderName.baseline
                    topMargin: Theme.paddingSmall
                    right: parent.right
                }
                HighlightImage {
                    visible: model.priority != EmailMessageListModel.NormalPriority
                    source: Utils.priorityIcon(model.priority)
                }

                HighlightImage {
                    visible: model.hasAttachments
                    source: "image://theme/icon-s-attach?"
                }
                HighlightImage {
                    visible: model.hasCalendarInvitation
                    source: "image://theme/icon-s-date?"
                }
                HighlightImage {
                    visible: model.hasSignature
                    source: "image://theme/icon-s-certificates"
                }
            }
        }
        Label {
            id: subjectText

            text: model.parsedSubject != ""
                  ? Theme.highlightText(model.parsedSubject, (highlightSubject ? searchString : ""), Theme.highlightColor)
                  : //: Empty subject
                    //% "(Empty subject)"
                    qsTrId("jolla-email-la-no_subject")
            textFormat: Text.StyledText
            font.pixelSize: Theme.fontSizeSmall
            opacity: model.readStatus ? Theme.opacityHigh : 1.0
            width: parent.width - icons.width
            anchors {
                left: parent.left
                right: parent.right
                rightMargin: Screen.sizeCategory >= Screen.Large
                             ? Theme.paddingLarge + icons.width
                             : Theme.paddingMedium + icons.width
            }
            truncationMode: TruncationMode.Fade
        }

        Label {
            text: model.preview != "" ? Theme.highlightText(model.preview, (highlightBody ? searchString : ""),
                                                            Theme.primaryColor)
                                      : // it should not show empty preview when preview is not retrived yet, first sync for e.g
                                        //: Empty preview
                                        //% "(Empty preview)"
                                        qsTrId("jolla-email-la-no_preview")
            textFormat: Text.StyledText
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.highlightColor
            opacity: model.readStatus ? Theme.opacityHigh : 1.0

            maximumLineCount: Screen.sizeCategory >= Screen.Large ? 1 : ( model.readStatus ? 2 : 3)
            lineHeight: subjectText.height - Math.round(Theme.paddingSmall/2)
            lineHeightMode: Text.FixedHeight
            width: parent.width
            wrapMode: Text.Wrap
            elide: Text.ElideRight
        }
    }

    Component {
        id: contextMenuComponent
        ContextMenu {
            MenuItem {
                //% "Move to"
                text: qsTrId("jolla-email-me-move_to")
                onClicked: {
                    pageStack.animatorPush(Qt.resolvedUrl("MoveToPage.qml"),
                                           { msgId: model.messageId,
                                             accountKey: emailAgent.accountIdForMessage(model.messageId)})
                }
            }
            MenuItem {
                visible: model.readStatus
                //% "Mark as unread"
                text: qsTrId("jolla-email-me-mark-unread")
                onDelayedClick: emailAgent.markMessageAsUnread(model.messageId)
            }
            MenuItem {
                visible: !model.readStatus
                //% "Mark as read"
                text: qsTrId("jolla-email-me-mark-read")
                onDelayedClick: emailAgent.markMessageAsRead(model.messageId)
            }
            MenuItem {
                //% "Delete"
                text: qsTrId("jolla-email-me-delete")
                onClicked: messageItem.remove()
            }
        }
    }
}
