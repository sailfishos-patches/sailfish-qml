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
    property FolderListModel folderModel

    signal folderSelected(int folderId, string folderName)

    FolderListProxyModel {
        id: folderProxyModel
        sourceModel: root.folderModel
        includeRoot: true
    }

    SilicaListView {
        anchors.fill: parent
        model: folderProxyModel
        header: PageHeader {
            //% "Parent folder"
            title: qsTrId("jolla-email-newfolder_select_parent_title")
        }

        delegate: FolderItem {
            enabled: canCreateChild
            isCurrentItem: folderId == root.selectedFolderId
            // don't show local folders in the list
            hidden: Utils.isLocalFolder(folderId)
            onClicked: {
                root.folderSelected(folderId, folderDisplayName)
            }
        }
        VerticalScrollDecorator {}

        Component.onCompleted: {
            // Scroll list to current folder
            // Take into account 'Root' folder on top of the list
            currentIndex = root.folderModel.indexFromFolderId(selectedFolderId) + 1
        }
    }
}
