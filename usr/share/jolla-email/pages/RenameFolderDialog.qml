/*
 * Copyright (c) 2018 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1

Dialog {
    id: root

    property int folderId
    property string folderName
    canAccept: nameEdit.text.length > 0 && nameEdit.text !== folderName
    onAccepted: {
        emailAgent.renameFolder(folderId, nameEdit.text)
    }

    Column {
        width: parent.width
        DialogHeader {
            //% "Rename"
            acceptText: qsTrId("email-ph-folder_rename_title")
        }

        TextField {
            id: nameEdit
            width: parent.width
            text: folderName
            focus: true
            //% "Enter folder name"
            placeholderText: qsTrId("email-ph-folder_rename")
            EnterKey.enabled: root.canAccept
            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
            EnterKey.onClicked: root.accept()
        }
    }
}
