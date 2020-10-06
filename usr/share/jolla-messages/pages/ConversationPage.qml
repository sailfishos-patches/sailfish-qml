/*
 * Copyright (c) 2012 - 2020 Jolla Ltd.
 * Copyright (c) 2019 - 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Messages 1.0
import org.nemomobile.contacts 1.0
import org.nemomobile.commhistory 1.0
import "conversation"
import "common"

Page {
    id: conversationPage

    property bool editorFocus
    property bool hasDraftText: !textInput.empty
    property string draftText: textInput.text

    function forceEditorFocus() {
        textInput.forceActiveFocus()
    }

    function setText(text) {
        textInput.text = text
        textInput.cursorPosition = text.length
    }

    function markAsRead() {
        if (status !== PageStatus.Active || !Qt.application.active)
            return

        var group = conversation.contactGroup
        if (group && group.unreadMessages > 0)
            group.markAsRead()
    }

    function saveDraftState() {
        textInput.saveDraftState()
        textInput.reset()
    }

    Component.onCompleted: mainWindow.conversationPage = conversationPage
    Component.onDestruction: mainWindow.conversationPage = null

    onStatusChanged: {
        if (status === PageStatus.Active)
            markAsRead()
    }

    Connections {
        target: Qt.application

        onActiveChanged: markAsRead()
    }

    Connections {
        target: conversation.contactGroup

        onUnreadMessagesChanged: markAsRead()
    }

    Connections {
        target: conversation

        onContactGroupChanged: markAsRead()
        onTargetChanged: textInput.reset()
    }

    ConversationHeader {
        id: conversationHeader

        readonly property bool active: conversationPage.isPortrait
        enabled: visible && (conversationPage.status === PageStatus.Active)
                 && (conversation.hasPhoneNumber || !conversation.message.isSMS)
        visible: active
        text: conversation.title
        showPhoneIcon: conversation.hasPhoneNumber
    }

    MessagesView {
        id: messages
        focus: true

        // NOTE: clip is necessary because:
        // * we need to clip the content that would otherwise overlap with the ConversationHeader
        // * design wants the delegates to have rounded rectangles that only have rounding on the right,
        //   which we achieve by making a proper rounded rectangle and clipping its left rounded corners.
        clip: true

        anchors {
            fill: parent
            topMargin: conversationHeader.active ? conversationHeader.height : 0
        }

        model: CommConversationModel {
            useBackgroundThread: true
            contactGroup: conversation.contactGroup
        }

        // Use a placeholder for the ChatTextInput to avoid re-creating the input
        header: Item {
            width: messages.width
            height: headerArea.height
        }

        Item {
            id: headerArea
            y: messages.headerItem.y
            parent: messages.contentItem
            width: parent.width
            height: textInput.y + textInput.height

            SmsDisabledBanner {
                id: smsDisabledBanner
                localUid: conversation.message.hasChannel
                          ? conversation.message.channels[0].localUid
                          : ""
            }

            AccountErrorLabel {
                id: accountErrors
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                }

                localUid: conversation.message.hasChannel
                          ? conversation.message.channels[0].localUid
                          : ""
                visible: !smsDisabledBanner.active
            }

            ConversationTextInput {
                id: textInput

                y: smsDisabledBanner.active ? smsDisabledBanner.height : accountErrors.height
                editorFocus: conversationPage.editorFocus
                enabled: accountErrors.simErrorState.length === 0
                         && (!textInput.needsSimFeatures || MessageUtils.messagingPermitted)
                         && senderSupportsReplies
                         && conversation.message.hasChannel

                onReadyToSend: {
                    if (textInput.needsSimFeatures && (!MessageUtils.messagingPermitted
                            || !MessageUtils.testCanUseSim(accountErrors.simErrorState))) {
                        return
                    }
                    saveDraftState()
                    conversation.message.sendMessage(text)
                    text = ""
                }
            }
        }
    }

    ContactPageAttacher {
        basePage: conversationPage
        people: conversation.people
    }

    AccessContactCardHint {
        enabled: conversationPage.canNavigateForward
    }
}
