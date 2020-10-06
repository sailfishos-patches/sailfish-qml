/*
 * Copyright (c) 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Email 0.1

Column {
    id: root
    x: Theme.horizontalPageMargin
    width: parent ? parent.width - 2 * x : implicitWidth

    property alias accountId: folderModel.accountKey
    property alias typeFilter: folderModel.typeFilter
    readonly property alias folderCount: folderModel.count
    readonly property alias syncFolderList: folderModel.syncFolderList

    FolderListFilterTypeModel {
        id: folderModel
        typeFilter: [
            EmailFolder.NormalFolder,
            EmailFolder.InboxFolder,
            EmailFolder.OutboxFolder,
            EmailFolder.SentFolder,
            EmailFolder.DraftsFolder,
            EmailFolder.TrashFolder,
            EmailFolder.JunkFolder
        ]
    }

    Repeater {
        anchors {
            left: parent.left
            leftMargin: Theme.paddingLarge
            right: parent.right
        }
        model: folderModel
        delegate: Item {
            width: parent.width
            height: Theme.itemSizeExtraSmall
            TextSwitch {
                text: folderName
                anchors {
                    left: parent.left
                    leftMargin: Theme.paddingLarge * folderNestingLevel
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                automaticCheck: false
                checked: syncEnabled
                onClicked: syncEnabled = !checked
            }
        }
    }

    Label {
        visible: folderModel.count === 0
        //% "No folders, account has not been synced yet."
        text: qsTrId("settings-accounts-la-no_folder")
        width: parent.width
        wrapMode: Text.Wrap
        color: Theme.secondaryHighlightColor
    }
}
