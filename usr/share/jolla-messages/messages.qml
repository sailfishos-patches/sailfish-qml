/*
 * Copyright (c) 2013 - 2021 Jolla Ltd.
 * Copyright (c) 2021 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Messages 1.0
import Sailfish.Share 1.0
import Nemo.DBus 2.0
import org.nemomobile.messages.internal 1.0
import org.nemomobile.commhistory 1.0
import org.nemomobile.contacts 1.0
import "pages"
import "pages/common"

ApplicationWindow {
    id: mainWindow

    property Page mainPage
    property Page conversationPage
    property Page editorPage: {
        // When there is a text editing page in the stack (not necessarily at the top,
        // as another page may be invoked from an editing page)
        // Reevaluate on pageStack changes
        return pageStack.currentPage, pageStack.find(function(page) { return page.hasOwnProperty('hasDraftText') })
    }
    property bool editorActive: editorPage != null && editorPage.hasDraftText
    property string draftText: editorActive ? editorPage.draftText : ''

    property alias conversationGroup: conversation.contactGroup
    property alias conversationRecipients: conversation.recipients

    property Component _conversationPageComponent

    cover: Qt.resolvedUrl("cover/MessagesCover.qml")
    allowedOrientations: defaultAllowedOrientations
    _defaultPageOrientations: Orientation.All
    _defaultLabelFormat: Text.PlainText

    Component.onCompleted: {
        // Get a head start on compiling the ConversationPage to reduce the amount of time spent
        // waiting the first time a page is pushed.
        _conversationPageComponent = Qt.createComponent("pages/ConversationPage.qml", Component.Asynchronous, mainWindow)
    }

    onConversationPageChanged: {
        if (conversationPage === null) {
            // Any conversation we had selected is now cleared
            conversation.clear()
        }
    }

    CurrentConversation {
        id: conversation
        modelPopulated: resolvePeopleModel.populated
    }

    TelepathyChannelManager {
        id: channelManager
        handlerName: "org.sailfishos.Messages"
    }

    CommGroupManager {
        id: groupManager
        useBackgroundThread: true
    }

    CommContactGroupModel {
        id: groupModel
        manager: groupManager

        property var unreadGroups: [ ]

        onContactGroupCreated: {
            if (group.unreadMessages > 0) {
                unreadGroups.push(group)
                unreadSignalTimer.start()
            }
        }

        onContactGroupChanged: {
            var index = unreadGroups.indexOf(group)
            if (group.unreadMessages > 0 && index < 0) {
                unreadGroups.push(group)
                unreadSignalTimer.start()
            } else if (group.unreadMessages === 0 && index >= 0) {
                unreadGroups.splice(index, 1)
                unreadSignalTimer.start()
            }
        }

        onContactGroupRemoved: {
            var index = unreadGroups.indexOf(group)
            if (index >= 0) {
                unreadGroups.splice(index, 1)
                unreadSignalTimer.start()
            }
        }

        onUnreadGroupsChanged: {
            if (!Qt.application.active)
                mainWindow.setPageAutomatically()
        }
    }

    Timer {
        id: unreadSignalTimer
        interval: 1
        onTriggered: groupModel.unreadGroupsChanged()
    }

    PeopleModel {
        id: resolvePeopleModel

        // Specify the PhoneNumberRequired flag to ensure that all phone number
        // data will be loaded before the model emits populated.
        // This ensures that we resolve numbers to contacts appropriately, in
        // the case where we attempt to message a newly-created contact via
        // the action shortcut icon in the contact card.
        requiredProperty: PeopleModel.PhoneNumberRequired
    }

    CommHistoryService {
        id: commHistory

        observedGroups: {
            if (!Qt.application.active)
                return [ ]
            return conversation.contactGroup ? conversation.contactGroup.groups : [ ]
        }

        inboxObserved: Qt.application.active && pageStack.depth === 1
    }

    DBusAdaptor {
        service: "org.sailfishos.Messages"
        path: "/share"
        iface: "org.sailfishos.share"

        function shareSms(shareActionConfiguration) {
            var shareAction = shareActionComponent.createObject(null)
            shareAction.loadConfiguration(shareActionConfiguration)
            var resource = shareAction.resources[0]
            if (!resource) {
                console.warn("Undefined share resource!")
                shareAction.destroy()
                return
            }
            var body = ""
            if (resource.type === "text/plain" || resource.type === "text/x-url") {
                body = (resource.status || "")
            } else {
                console.warn("Unrecognised resource type:", resource.type)
            }
            newMessage(PageStackAction.Immediate, body)
            shareAction.destroy()
            activateWindow()
        }

        function shareMms(shareActionConfiguration) {
            showMainPage(PageStackAction.Immediate)
            pageStack.push(Qt.resolvedUrl("pages/MmsShare.qml"),
                           { "shareActionConfiguration": shareActionConfiguration },
                           PageStackAction.Immediate)
            activateWindow()
        }
    }

    Component {
        id: shareActionComponent
        ShareAction { }
    }

    function showMainPage(operationType) {
        pageChangedManually = true

        if (mainPage) {
            // Pop down to the main page
            pageStack.pop(mainPage, operationType)
        } else {
            mainPage = pageStack.push(Qt.resolvedUrl("pages/MainPage.qml"), {}, PageStackAction.Immediate)
        }
    }

    function showConversationPage(operationType, focus, sync) {
        pageChangedManually = true

        if (!conversation.hasConversation) {
            showMainPage(operationType)
            return
        }

        if (conversationPage) {
            pageStack.pop(conversationPage, operationType)

            // Set editor focus
            if (focus)
                conversationPage.forceEditorFocus()
            return
        }

        if (pageStack.depth > 1) {
            pageStack.animatorReplaceAbove(mainPage, Qt.resolvedUrl("pages/ConversationPage.qml"),
                                           { "editorFocus": focus }, operationType)
        } else {
            if (pageStack.depth == 0)
                showMainPage(PageStackAction.Immediate)

            if (!!sync) {
                pageStack.push(Qt.resolvedUrl("pages/ConversationPage.qml"),
                               { "editorFocus": focus }, operationType)
            } else {
                pageStack.animatorPush(Qt.resolvedUrl("pages/ConversationPage.qml"),
                                       { "editorFocus": focus }, operationType)
            }
        }
    }

    function sendMessage(localUid, remoteUid, message) {
        groupManager.createOutgoingMessageEvent(-1 /*groupId*/, localUid, remoteUid, message, function(eventId) {
            var channel = channelManager.getConversation(localUid, remoteUid)
            channel.sendMessage(message, eventId)
        })
    }

    function loadAndShowSMSConversation(remoteUids, body) {
        loadAndShowConversation(MessageUtils.telepathyAccounts.ringAccountPath, remoteUids, body, true)
    }

    function loadAndShowConversation(localUid, remoteUids, body, focus) {
        // Exception handler to work around a Qt bug causing errors to not print when called from C++ code
        try {
            // If there is a draft in progress, save the state before changing conversation
            if (editorActive) {
                editorPage.saveDraftState()
            }

            if (MessageUtils.isSMS(localUid) && remoteUids.length > 1) {
                conversation.message.setBroadcastChannel(localUid, remoteUids)
            } else {
                conversation.message.setChannel(localUid, remoteUids[0])
            }
            conversation.fromMessageChannel()

            showConversationPage(Qt.application.active ? PageStackAction.Animated : PageStackAction.Immediate,
                                 focus, true)
            if (body !== undefined && body.length > 0)
                conversationPage.setText(body)
            activate()
        } catch (err) {
            console.log("loadAndShowConversation error:", err)
        }
    }

    function showConversation(group) {
        conversation.fromContactGroup(group)
        showConversationPage(PageStackAction.Animated, false)
    }

    function showGroupsList() {
        try {
            showMainPage(PageStackAction.Immediate)
            activate()
        } catch (err) {
            console.log("showGroupsList error:", err)
        }
    }

    function activateWindow() {
        try {
            if (pageStack.currentPage === null)
                showMainPage(PageStackAction.Immediate)
            activate()
        } catch (err) {
            console.log("activateWindow error:", err)
        }
    }

    function newMessage(operationType, body) {
        showMainPage(PageStackAction.Immediate)
        conversation.clear()
        pageStack.animatorPush(Qt.resolvedUrl("pages/NewMessagePage.qml"),
                               { draftText: body || "" },
                               operationType === undefined ? PageStackAction.Immediate : operationType)
        activateWindow()
    }

    function groupMessageText(group) {
        if (group) {
            if (group.lastEventType == CommHistory.MMSEvent) {
                //% "Multimedia message"
                return qsTrId("messages-ph-mms_empty_text")
            }
            return group.lastMessageText
        }
        return ''
    }

    function groupRecipients(group) {
        var multiple = group.displayNames.length > 1
        return group.displayNames[0] + (multiple ? '\u2026' : '')
    }

    function eventStatusText(status, eventId) {
        if (status !== undefined) {
            if (status === CommHistory.PermanentlyFailedStatus
                    || (status === CommHistory.TemporarilyFailedStatus
                        && !channelManager.isPendingEvent(eventId))) {
                //% "Problem with sending message"
                return qsTrId("messages-send_status_failed")
            } else if (status === CommHistory.SendingStatus || status === CommHistory.TemporarilyFailedStatus) {
                // If the status is TemporarilyFailed, show it as sending, as that is commonly the true situation
                //% "Sending..."
                return qsTrId("messages-message_state_sending")
            } else if (status === CommHistory.DownloadingStatus) {
                //% "Downloading..."
                return qsTrId("messages-message_state_downloading")
            } else if (status === CommHistory.WaitingStatus) {
                //% "Waiting..."
                return qsTrId("messages-message_state_waiting")
            }
        }
        return ''
    }

    // True if the page has been changed since the last minimize (Qt.application.active=false) event,
    // in any way except for setPageAutomatically. This is used to avoid automatically replacing pages.
    property bool pageChangedManually

    Connections {
        target: Qt.application
        onActiveChanged: {
            // When minimized, allow the page to change automatically so that the cover matches the page when reopened
            // This is delayed 5 seconds to avoid changing pages if you quickly go out and back in the application
            if (!Qt.application.active) {
                autoPageTimer.start()
            } else {
                autoPageTimer.stop()
            }
        }
    }

    Connections {
        target: pageStack
        onCurrentPageChanged: mainWindow.pageChangedManually = true
    }

    Timer {
        id: autoPageTimer
        interval: 5000
        onTriggered: mainWindow.pageChangedManually = false
    }

    function setPageAutomatically() {
        if (pageChangedManually || Qt.application.active || editorActive) {
            return
        }

        if (groupModel.unreadGroups.length == 1) {
            var group = groupModel.unreadGroups[0]

            if (group != conversation.contactGroup) {
                conversation.fromContactGroup(group)
                showConversationPage(PageStackAction.Immediate, false)
            }
        } else if (groupModel.unreadGroups.length > 0) {
            showMainPage(PageStackAction.Immediate)
        }

        pageChangedManually = false
    }

    function createComponent(source, mode) {
        return Qt.createComponent(source, mode)
    }

}

