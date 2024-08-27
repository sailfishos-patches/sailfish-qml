/*
 * Copyright (c) 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

Page {
    property alias accountId: folderListView.accountId

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        VerticalScrollDecorator {}

        Column {
            id: content
            width: parent.width
            bottomPadding: Theme.paddingLarge

            PageHeader {
                //% "Folders to sync"
                title: qsTrId("settings_accounts-he-page_folder_sync")
            }

            FolderListView {
                id: folderListView
            }
        }
    }
}
