/*
 * Copyright (c) 2013 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import Sailfish.Messages 1.0
import Sailfish.Telephony 1.0
import org.nemomobile.contacts 1.0
import org.nemomobile.commhistory 1.0
import "conversation"
import "common"

MessageComposerPage {
    id: newMessagePage

    // Always prevent automatic page switching
    property bool hasDraftText: true
    property alias draftText: textInput.text

    property bool _restrictToPhoneNumber

    function saveDraftState() {
        textInput.saveDraftState()
        textInput.reset()
    }

    errorLabel.localUid: conversation.message.hasChannel
                         ? conversation.message.channels[0].localUid
                         : ""
    recipientField.requiredProperty: !MessageUtils.hasModem
                                     ? PeopleModel.AccountUriRequired
                                     : (_restrictToPhoneNumber ? PeopleModel.PhoneNumberRequired
                                                               : (PeopleModel.AccountUriRequired | PeopleModel.PhoneNumberRequired))

    onFocusTextInput: textInput.forceActiveFocus()

    onRecipientSelectionChanged: {
        //XXX Since the user chooses the type when they choose the contact, the type menu isn't needed
        if (recipientField.selectedContacts.get(0).propertyType === "accountUri") {
            // Only one contact allowed for IM
            recipientField.multipleAllowed = false
        } else if (recipientField.selectedContacts.get(0).propertyType === "phoneNumber") {
            _restrictToPhoneNumber = true
            recipientField.multipleAllowed = true
        } else {
            _restrictToPhoneNumber = false
            recipientField.multipleAllowed = true
        }

        validateRecipients()
        if (validatedRemoteUids.length === 0) {
            conversation.clear()
            return
        }

        if (validatedRemoteUids.length === 1) {
            conversation.message.setChannel(validatedLocalUid, validatedRemoteUids[0])
        } else {
            conversation.message.setBroadcastChannel(validatedLocalUid, validatedRemoteUids)
        }
        conversation.fromMessageChannel()
    }

    inputContent: [
        ConversationTextInput {
            id: textInput

            enabled: newMessagePage.errorLabel.simErrorState.length === 0
                     && (!textInput.needsSimFeatures || MessageUtils.messagingPermitted)
                     && senderSupportsReplies
            canSend: text.length > 0 && newMessagePage.validatedRemoteUids.length > 0

            // If the recipients list is modified, the event must be recreated to update the group associations
            recreateDraftEvent: true

            onReadyToSend: {
                if (textInput.needsSimFeatures && (!MessageUtils.messagingPermitted
                        || !MessageUtils.testCanUseSim(newMessagePage.errorLabel.simErrorState))) {
                    return
                }
                conversation.message.sendMessage(text)
                text = ""
                mainWindow.showConversationPage(PageStackAction.Immediate, true)
            }
        }
    ]

    ContactPageAttacher {
        basePage: newMessagePage
        people: conversation.people
    }
}
