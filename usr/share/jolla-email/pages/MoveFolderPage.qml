/*
 * Copyright (c) 2018 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1
import "utils.js" as Utils

Page {
    id: root

    property int selectedFolderId: -1
    property int folderId
    property int parentFolderId
    property FolderListModel folderModel

    onStatusChanged: {
        if (status === PageStatus.Deactivating) {
            if (selectedFolderId != -1) {
                emailAgent.moveFolder(folderId, selectedFolderId)
            }
        }
    }

    FolderListProxyModel {
        id: folderProxyModel
        sourceModel: root.folderModel
        includeRoot: true
    }

    SilicaListView {
        model: folderProxyModel
        header: PageHeader {
            //: Move folder page header
            //% "Select folder:"
            title: qsTrId("email-ph-folder_move")
        }

        anchors.fill: parent

        delegate: FolderItem {
            enabled: canCreateChild &&
                     folderId != root.folderId &&
                     folderId != root.parentFolderId
            // don't show local folders and descendant folders in the list
            hidden: Utils.isLocalFolder(folderId) || root.folderModel.isFolderAncestorOf(folderId, root.folderId)
            highlighted: folderId == root.selectedFolderId
            isCurrentItem: folderId == root.folderId
            onClicked: {
                root.selectedFolderId = folderId
                pageStack.pop()
            }
        }
        VerticalScrollDecorator {}

        Component.onCompleted: {
            // Scroll list to current folder
            // Take into account 'Root' folder on top of the list
            currentIndex = root.folderModel.indexFromFolderId(folderId) + 1
        }
    }
}
