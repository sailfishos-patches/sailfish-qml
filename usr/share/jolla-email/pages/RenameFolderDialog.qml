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
    canAccept: nameEdit.acceptableInput

    onAcceptBlocked: {
        if (!nameEdit.acceptableInput) {
            nameEdit.errorHighlight = true
        }
    }

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
            text: folderName
            focus: true

            //% "Folder name"
            label: qsTrId("email-la-folder_rename")
            //% "New folder name required"
            description: errorHighlight ? qsTrId("email-la-folder_rename_error") : ""

            acceptableInput: text.length > 0 && text !== folderName
            onActiveFocusChanged: if (!activeFocus) errorHighlight = !acceptableInput
            onAcceptableInputChanged: if (acceptableInput) errorHighlight = false

            EnterKey.enabled: root.canAccept
            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
            EnterKey.onClicked: root.accept()
        }
    }
}
