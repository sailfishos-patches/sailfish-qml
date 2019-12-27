/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1
import "utils.js" as Utils

SilicaListView {
    id: messageListView

    property alias folderAccessor: messageModel.folderAccessor
    property alias sortBy: messageModel.sortBy
    property alias accountId: folder.parentAccountId
    property alias messageCount: messageModel.count
    readonly property alias folderId: folder.folderId
    readonly property alias folderType: folder.folderType
    readonly property bool isDraftsFolder: folderType == EmailFolder.DraftsFolder
    readonly property bool isOutboxFolder: folderType === EmailFolder.OutboxFolder
    readonly property alias isOutgoingFolder: folder.isOutgoingFolder
    readonly property bool showGetMoreMails: !(mailAccountListModel.customFieldFromAccountId("showMoreMails", accountId) == "false")
    readonly property int fetchMore: 50
    readonly property int getMore: 20
    property bool waitToFetchMore
    property bool errorOccurred
    property string lastErrorText


    function sendAll() {
        if (isOutboxFolder) {
            emailAgent.processSendingQueue(accountId)
        } else {
            console.log("Trying to process sending queue for something else than outbox.")
        }
    }

    function synchronize(force) {
        if (isOutboxFolder)
            return

        var key = "sync_" + accountId.toString() + "_" + folder.folderId.toString()
        var now = Date.now()

        if (typeof force == "boolean" && !force && (!Utils.canSyncFolder(key, now) || !emailAgent.isOnline())) {
            return
        }

        // Store both manual sync and navigation between folders
        // time stamps.
        Utils.updateRecentSync(key, now)

        emailAgent.exportUpdates(accountId)
        emailAgent.retrieveMessageList(accountId, folder.folderId)
    }

    function removeMessage(id) {
        var index = messageModel.indexFromMessageId(id)
        currentIndex = index
        positionViewAtIndex(index, ListView.Contain)
        currentItem.remove()
    }

    anchors.fill: parent
    model: EmailMessageListModel {
        id: messageModel

        currentDate: app.today
        limit: app.defaultMessageListLimit
        // reset limit upon content change
        onFolderAccessorChanged: {
            limit = app.defaultMessageListLimit
        }

        onCurrentDateChanged: Utils.updateForDateChange(messageModel, messageListView)
    }

    header: MessageListHeader {
        folderName: emailAgent.currentSynchronizingAccountId === accountId
                    //: Updating header
                    //% "Updating..."
                    ? qsTrId("jolla-email-he-updating")
                    : Utils.standardFolderName(folder.folderType, folder.displayName)
        count: emailAgent.currentSynchronizingAccountId === accountId ? 0 : folder.folderUnreadCount
        errorText: errorOccurred ? lastErrorText : ""
        onHeightChanged: {
            // If an error message causes the header height to change, compensate by moving the scroll position
            if ((messageListView.contentY >= messageListView.originY)
                    && (messageListView.contentY < messageListView.originY + Theme.itemSizeSmall)
                    && (!messageListView.dragging)) {
                messageListView.contentY = messageListView.originY
            }
        }
    }

    footer: Item {
        width: messageListView.width
        height: Theme.paddingLarge
    }

    section {
        property: _sectionProperty()
        criteria: _sectionCriteria()

        delegate: SectionHeader {
            text: _sectionDelegateText(section)
            height: text === "" ? 0 : Theme.itemSizeExtraSmall
            horizontalAlignment: Text.AlignHCenter
            font.capitalization: (messageListView.model.sortBy == EmailMessageListModel.Sender
                                  || messageListView.model.sortBy == EmailMessageListModel.Subject)
                                 ? Font.AllUppercase : Font.MixedCase

            function _sectionDelegateText(section) {
                var sortBy = messageListView.model.sortBy
                if (sortBy === EmailMessageListModel.Time) {
                    return Format.formatDate(section, Formatter.TimepointSectionRelative)
                } else if (sortBy === EmailMessageListModel.Size) {
                    if (section == "0") {
                        //: Section header for small size emails
                        //% "Small (<100 KB)"
                        return qsTrId("jolla-email-la-small_size")
                    } else if (section == "1") {
                        //: Section header for medium size emails
                        //% "Medium (100-500 KB)"
                        return qsTrId("jolla-email-la-medium_size")
                    } else {
                        //: Section header for large size emails
                        //% "Large (>500 KB)"
                        return qsTrId("jolla-email-la-large_size")
                    }
                } else if (sortBy === EmailMessageListModel.ReadStatus) {
                    if (section == "true") {
                        //: Read emails section header
                        //% "Read emails"
                        return qsTrId("jolla-email-la-read_email")
                    } else {
                        //: Unread emails section header
                        //% "Unread emails"
                        return qsTrId("jolla-email-la-unread_email")
                    }
                } else if (sortBy === EmailMessageListModel.Priority) {
                    // assuming javascript handling string and enum comparison
                    if (section == EmailMessageListModel.HighPriority) {
                        //: High priority section header
                        //% "High"
                        return qsTrId("jolla-email-la-high_priority")
                    } else if (section == EmailMessageListModel.LowPriority) {
                        //: Low priority section header
                        //% "Low"
                        return qsTrId("jolla-email-la-low_priority")
                    } else {
                        //: Normal priority section header
                        //% "Normal"
                        return qsTrId("jolla-email-la-normal_priority")
                    }
                } else if (sortBy === EmailMessageListModel.Attachments) {
                    if (section == "true") {
                        //: Contains attachments section header
                        //% "Contains attachments"
                        return qsTrId("jolla-email-la-contains_attachments")
                    } else {
                        //: No attachments section header
                        //% "No attachments"
                        return qsTrId("jolla-email-la-no_attachments")
                    }
                } else {
                    return section
                }
            }
        }
    }

    onAtYEndChanged: {
        if (atYEnd && messageModel.canFetchMore) {
            if (quickScrollAnimating) {
                waitToFetchMore = true
            } else {
                messageModel.limit = messageModel.limit + fetchMore
            }
        }
    }

    onQuickScrollAnimatingChanged: {
        if (!quickScrollAnimating && waitToFetchMore) {
            waitToFetchMore = false
            messageModel.limit = messageModel.limit + fetchMore
        }
    }

    Binding {
        target: app
        property: "inboxUnreadCount"
        when: folder.folderType == EmailFolder.InboxFolder
        value: folder.folderUnreadCount
    }

    EmailFolder {
        id: folder
        folderAccessor: messageModel.folderAccessor
    }

    PullDownMenu {
        busy: app.syncInProgress

        MenuItem {
            //: Selects message list sort method
            //% "Sort by: %1"
            text: qsTrId("jolla-email-me-sort_by").arg(Utils.sortTypeText(messageModel.sortBy))
            visible: messageListView.count > 0
            onClicked: {
                // Don't show sort by sender for outgoing folders
                var obj = pageStack.animatorPush(Qt.resolvedUrl("SortPage.qml"),
                               { isOutgoingFolder: folder.isOutgoingFolder })
                obj.pageCompleted.connect(function(page) {
                    page.sortSelected.connect(function(sortType) {
                        messageModel.sortBy = sortType
                        pageStack.pop()
                    })
                })
            }
        }

        MenuItem {
            //% "Select messages"
            text: qsTrId("jolla-email-me-select_messages")
            visible: messageListView.count > 0
            onClicked: {
                pageStack.animatorPush(Qt.resolvedUrl("MultiSelectionPage.qml"), {
                                           removeRemorse: removeRemorse,
                                           selectionModel: messageModel,
                                           accountId: accountId,
                                           folderId: folder.folderId
                                       })
            }
        }

        MenuItem {
            //: Search from messages
            //% "Search"
            text: qsTrId("jolla-email-me-search")
            onClicked: {
                pageStack.animatorPush(Qt.resolvedUrl("SearchPage.qml"), { accountId: accountId })
            }
        }

        MenuItem {
            //: Send all messages currently in the outbox
            //% "Send all"
            text: isOutboxFolder ? qsTrId("jolla-email-me-send-all")
                                   //: Synchronise account menu item
                                   //% "Sync"
                                 : qsTrId("jolla-email-me-sync")
            enabled: !isOutboxFolder || (isOutboxFolder && messageListView.count > 0)
            onClicked: {
                if (isOutboxFolder) {
                    sendAll()
                } else {
                    synchronize()
                }
            }
        }

        MenuItem {
            enabled: mailAccountListModel.numberOfTransmitAccounts > 0
            //: New message menu item
            //% "New Message"
            text: qsTrId("jolla-email-me-new_message")
            onClicked: {
                pageStack.animatorPush(Qt.resolvedUrl("ComposerPage.qml"), { accountId: accountId })
            }
        }
    }

    PushUpMenu {
        visible: !messageModel.canFetchMore && showGetMoreMails
        busy: app.syncInProgress

        MenuItem {
            //% "Get more mails"
            text: qsTrId("jolla-email-me-get_more_mails")
            onClicked: {
                if (messageModel.limit) {
                    messageModel.limit = messageModel.limit + getMore
                }
                emailAgent.getMoreMessages(folder.folderId, getMore)
            }
        }
    }

    MessageRemorsePopup {
        id: removeRemorse
    }

    ViewPlaceholder {
        opacity: messageListView.count === 0 ? 1.0 : 0.0

        text: {
            if (!app.syncInProgress) {
                //: Empty message list placeholder label
                //% "No emails"
                return qsTrId("jolla-email-la-empty_list")
            }
            return ""
        }
    }

    delegate: messageModel.sortBy == EmailMessageListModel.Subject
                ? subjectSortedDelegate
                : (messageModel.sortBy == EmailMessageListModel.Time
                    ? timeSortedDelegate
                    : defaultSortedDelegate)

    Component {
        id: subjectSortedDelegate
        MessageListViewItem {
            //% "(Empty subject)"
            primaryLine: model.subject != "" ? model.subject : qsTrId("jolla-email-la-no_subject")
            secondaryLine: model.senderDisplayName != "" ? model.senderDisplayName : model.senderEmailAddress
            showRecipientsName: folder.isOutgoingFolder
            isDraftsFolder: messageListView.isDraftsFolder
        }
    }
    Component {
        id: timeSortedDelegate
        MessageListViewItem {
            showRecipientsName: folder.isOutgoingFolder
            isDraftsFolder: messageListView.isDraftsFolder
        }
    }
    Component {
        id: defaultSortedDelegate
        MessageListViewItem {
            date: Format.formatDate(model.qDateTime, Formatter.TimepointRelativeCurrentDay)
            showRecipientsName: folder.isOutgoingFolder
            isDraftsFolder: messageListView.isDraftsFolder
        }
    }

    VerticalScrollDecorator {}

    function _sectionProperty() {
        var sortBy = messageModel.sortBy
        if (sortBy === EmailMessageListModel.Time) {
            return "timeSection"
        } else if (sortBy === EmailMessageListModel.Sender) {
            return "senderDisplayName"
        } else if (sortBy === EmailMessageListModel.Size) {
            return "sizeSection"
        } else if (sortBy === EmailMessageListModel.ReadStatus) {
            return "readStatus"
        } else if (sortBy === EmailMessageListModel.Priority) {
            return "priority"
        } else if (sortBy === EmailMessageListModel.Attachments) {
            return "hasAttachments"
        } else if (sortBy === EmailMessageListModel.Subject) {
            return "subject"
        } else if (sortBy === EmailMessageListModel.Recipients) {
            return "recipients"
        }
    }

    function _sectionCriteria() {
        var sortBy = messageListView.model.sortBy
        if (sortBy === EmailMessageListModel.Sender || sortBy === EmailMessageListModel.Subject
                || sortBy === EmailMessageListModel.Recipients) {
            return ViewSection.FirstCharacter
        } else {
            return ViewSection.FullString
        }
    }

    Connections {
        target: emailAgent

        onCurrentSynchronizingAccountIdChanged: {
            if (emailAgent.currentSynchronizingAccountId === folder.parentAccountId) {
                errorOccurred = false
            }
        }

        onError: {
            if (accountId === folder.parentAccountId) {
                errorOccurred = true
                lastErrorText = Utils.syncErrorText(syncError)
            }
        }
    }
}
