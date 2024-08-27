/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1
import "utils.js" as Utils

Page {
    property alias accountKey: folderModel.accountKey
    // Need either messageId or messageModel
    property int msgId
    property EmailMessageListModel messageModel
    property int currentFolder: emailAgent.folderIdForMessage(msgId)
    property int selectedFolder

    onStatusChanged: {
        if (status === PageStatus.Deactivating) {
            if (selectedFolder) {
                if (messageModel) {
                    messageModel.moveSelectedMessages(selectedFolder)
                    messageModel.deselectAllMessages()
                } else {
                    emailAgent.moveMessage(msgId, selectedFolder)
                }
            } else if (messageModel) {
                messageModel.deselectAllMessages()
            }
        }
    }

    FolderListModel {
        id: folderModel
    }

    SilicaListView {
        anchors.fill: parent
        model: folderModel
        header: PageHeader {
            //: Move to folder page header
            //% "Select Folder:"
            title: qsTrId("jolla-email-he-select_folder")
        }

        delegate: FolderItem {
            // don't show local folders in the list
            hidden: Utils.isLocalFolder(folderId)
            enabled: folderId != currentFolder && canHaveMessages
            onClicked: {
                selectedFolder = folderId
                pageStack.pop()
            }
        }

        VerticalScrollDecorator {}

        Component.onCompleted: {
            // Scroll list to current folder
            // Take into account 'Root' folder on top of the list
            currentIndex = folderModel.indexFromFolderId(currentFolder) + 1
        }
    }
}
