/*
 * Copyright (c) 2012 – 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1

Page {
    id: messageListPage

    property alias folderAccessor: messageListView.folderAccessor
    property Page folderListPage

    function removeMessage(id) {
        messageListView.removeMessage(id)
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            app.coverMode = "mainView"
            if (!app.syncInProgress
                    && Qt.application.state === Qt.ApplicationActive
                    && messageListView.folderType !== EmailFolder.InvalidFolder) {
                messageListView.synchronize(false)
            }

            if (folderListPage && !pageStack.nextPage(messageListPage)) {
                pageStack.pushAttached(folderListPage)
            }
        }
    }

    onFolderListPageChanged: {
        if (status === PageStatus.Active && folderListPage &&
                !pageStack.nextPage(messageListPage)) {
            pageStack.pushAttached(folderListPage)
        }
    }

    MessageListView {
        id: messageListView
    }

    Loader {
        anchors.fill: parent
        asynchronous: true
        // Note: doesn't update if content changes to different account later
        Component.onCompleted: {
            setSource(Qt.resolvedUrl("FolderListPage.qml"), {accountKey: messageListView.accountId})
        }

        onLoaded: folderListPage = item
        onStatusChanged: {
            if (status == Loader.Error && sourceComponent) {
                console.log(sourceComponent.errorString())
            }
        }
        onItemChanged: {
            if (item) {
                item.folderClicked.connect(function(accessor) {
                    messageListView.folderAccessor = accessor

                    // if the message list is sorted by sender and we are navigating to a outgoing folder,
                    // default to sort by recipients since sort by sender is not available for outgoing folders
                    if (messageListView.isOutgoingFolder && messageListView.sortBy == EmailMessageListModel.Sender) {
                        messageListView.sortBy = EmailMessageListModel.Recipients
                    } else if (!messageListView.isOutgoingFolder && messageListView.sortBy == EmailMessageListModel.Recipients) {
                        messageListView.sortBy = EmailMessageListModel.Sender
                    }

                    pageStack.navigateBack()
                })

                item.deletingFolder.connect(function(id) {
                    if (id === messageListView.folderId) {
                        var inbox = emailAgent.inboxFolderId(messageListView.accountId)
                        if (inbox > 0) {
                            var accessor = emailAgent.accessorFromFolderId(inbox)
                            messageListView.folderAccessor = accessor
                        } else {
                            console.log("Delete current folder: unable to set current folder to Inbox")
                        }
                    }
                })
            }
        }
    }

    FolderAccessHint {
        pageActive: messageListPage.status == PageStatus.Active && Qt.application.active && folderListPage
    }
}
