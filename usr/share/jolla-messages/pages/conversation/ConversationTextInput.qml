import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Messages 1.0
import Sailfish.Telephony 1.0
import org.nemomobile.contacts 1.0
import org.nemomobile.commhistory 1.0
import Sailfish.Contacts 1.0

ChatTextInput {
    id: chatInputArea

    property bool recreateDraftEvent: false
    readonly property bool senderSupportsReplies: conversation.hasPhoneNumber || !conversation.message.isSMS

    property bool onScreen: visible && Qt.application.active && page !== null && page.status === PageStatus.Active
    onOnScreenChanged: {
        if (!onScreen) {
            saveDraftState()
        }
    }

    property Page page: _findPage()
    function _findPage() {
        var parentItem = parent
        while (parentItem) {
            if (parentItem.hasOwnProperty('__silica_page')) {
                return parentItem
            }
            parentItem = parentItem.parent
        }
        return null
    }

    function reset() {
        Qt.inputMethod.commit()
        text = ""
        originalEventId = 0
        draftEvent.reset()
    }

    function saveDraftState() {
        Qt.inputMethod.commit()
        draftEvent.updateAndSave()
    }

    placeholderText: senderSupportsReplies
                     ? defaultPlaceholderText
                       //% "Sender does not support replies"
                     : qsTrId("messages-ph-sender_des_not_support_replies")

    messageTypeName: conversation.message.hasChannel
                     ? MessageUtils.accountDisplayName(conversation.people[0],
                                                       conversation.message.localUid,
                                                       conversation.message.remoteUids[0])
                     : ""

    presenceState: (conversation.message.hasChannel
                   && !conversation.message.isSMS
                   && conversation.message.remoteUids.length === 1)
                   ? MessageUtils.presenceForPersonAccount(conversation.people[0],
                                                           conversation.message.localUid,
                                                           conversation.message.remoteUids[0])
                   : Person.PresenceUnknown

    phoneNumberDescription: conversation.message.isSMS && conversation.people.length === 1
                            ? MessageUtils.phoneDetailsString(conversation.message.remoteUids[0], conversation.people)
                            : ""

    needsSimFeatures: conversation.message.isSMS

    Connections {
        target: conversation

        // If any contacts are incomplete, the CurrentConversation.peopleDetailsChanged signal
        // will be fired and that causes a refresh of the model. It covers a few other situations
        // where details may change as well.
        onPeopleDetailsChanged: {
            conversationTypeMenu.refresh()
        }
    }
    conversationTypeMenu.localUid: conversation.message.localUid
    conversationTypeMenu.remoteUid: conversation.message && conversation.message.remoteUids.length ? conversation.message.remoteUids[0] : ""
    conversationTypeMenu.people: conversation.people
    conversationTypeMenu.enabled: {
        if (conversationTypeMenu.count > 1) {
            return true
        }
        // The onScreen condition is to prevent a crash that looks similar
        // to https://bugreports.qt.io/browse/QTBUG-61261
        if ((conversationTypeMenu.count === 1) && onScreen) {
            var data = conversationTypeMenu.model.get(0)
            var remotes = [data.remoteUid]
            if (remotes[0].length === 0) {
                remotes = conversation.message.remoteUids
            }
            if (!conversation.message.matchChannel(data.localUid, remotes)) {
                return true
            }
        }
        return false
    }

    Connections {
        target: conversationTypeMenu

        onActivated: {
            var data = conversationTypeMenu.model.get(index)
            if (data === null)
                return
            var groupId = conversation.message.groupId
            var remotes = conversation.message.remoteUids

            var setChannel = function() {
                if (data.remoteUid !== "") {
                    conversation.message.setChannel(data.localUid, data.remoteUid)
                } else {
                    conversation.message.setBroadcastChannel(data.localUid, remotes, groupId)
                }
                chatInputArea.forceActiveFocus()
                conversationTypeMenu.closed.disconnect(setChannel)
            }
            conversationTypeMenu.closed.connect(setChannel)
        }
    }

    /* Draft messages are queried on load and group id change via DraftsModel.
     * If a draft message is loaded, the conversation type will be changed to
     * match it as well.
     *
     * When deactivated either by minimizing the app or by switching away from
     * the editing page, draft events are created, updated, or deleted.
     */

    DraftEvent {
        id: draftEvent

        onEventChanged: {
            if (freeText !== '' && chatInputArea.text === '') {
                chatInputArea.text = freeText
                chatInputArea.cursorPosition = chatInputArea.text.length
                chatInputArea.editorFocus = true
                /* For broadcast messages, we can assume we already have the right
                 * details, rather than trying to read them from the group, because
                 * there is only one valid communication method per unique group.
                 *
                 * For non-broadcast, make sure we're using the same one */
                if (!conversation.message.broadcast && remoteUids.length > 0) {
                    conversation.message.setChannel(localUid, remoteUids[0])
                }
            }
        }

        function updateAndSave() {
            if (chatInputArea.text === '') {
                if (eventId >= 0) {
                    deleteEvent()
                } else if (chatInputArea.originalEventId > 0) {
                    draftsModel.deleteEvent(chatInputArea.originalEventId);
                }
                reset()
                return
            }

            localUid = conversation.message.localUid
            remoteUids = conversation.message.remoteUids
            freeText = chatInputArea.text

            if (conversation.message.groupId >= 0) {
                groupId = conversation.message.groupId
            } else if (localUid !== '' && remoteUids.length > 0) {
                groupId = conversation.message.groupId = groupManager.ensureGroupExists(conversation.message.localUid, conversation.message.remoteUids)
            } else {
                return
            }

            save()

            if (chatInputArea.originalEventId > 0 && eventId != chatInputArea.originalEventId) {
                // We have altered the original draft, it can be removed
                draftsModel.deleteEvent(chatInputArea.originalEventId);
                chatInputArea.originalEventId = -1
            }
        }
    }

    property int originalEventId
    DraftsModel {
        id: draftsModel
        filterGroups: conversation.groupIds()
        onFilterGroupsChanged: draftQueryTimer.start()

        onModelReady: {
            draftEvent.event = draftsModel.event(0)
            originalEventId = draftEvent.eventId
            if (chatInputArea.recreateDraftEvent) {
                // Clear the ID so that this draft will be saved as a new event
                draftEvent.eventId = -1
            }
        }
    }

    Timer {
        id: draftQueryTimer
        interval: 1
        onTriggered: {
            if (draftsModel.filterGroups.length > 0)
                draftsModel.getEvents()
            else
                draftEvent.reset()
        }
    }
}
