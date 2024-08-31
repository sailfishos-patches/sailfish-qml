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

    property int parentFolderId
    property string parentFolderName
    property FolderListModel folderModel

    canAccept: folderNameField.acceptableInput

    onAcceptBlocked: {
        if (!folderNameField.acceptableInput) {
            folderNameField.errorHighlight = true
        }
    }

    onAccepted: {
        emailAgent.createFolder(folderNameField.text, folderModel.accountKey, parentFolderId)
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge
        Column {
            width: parent.width
            DialogHeader {
                id: dialogHeader
                //% "Create"
                acceptText: qsTrId("email-ph-folder_create")
            }
            TextField {
                id: folderNameField

                //% "Folder name"
                label: qsTrId("jolla-email-newfolder_folder_name_placeholder")
                //% "Folder name required"
                description: errorHighlight ? qsTrId("jolla-email-newfolder_folder_name_placeholder_error") : ""

                acceptableInput: text.length > 0
                onActiveFocusChanged: if (!activeFocus) errorHighlight = !acceptableInput
                onAcceptableInputChanged: if (acceptableInput) errorHighlight = false

                focus: true
                EnterKey.enabled: root.canAccept
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: root.accept()
            }

            ValueButton {
                id: valueButton
                //% "Parent folder"
                label: qsTrId("jolla-email-newfolder_parent_label")
                value: parentFolderName
                onClicked: {
                    var selector = pageStack.animatorPush(Qt.resolvedUrl("NewFolderParentSelectionPage.qml"), {
                                                              selectedFolderId: root.parentFolderId,
                                                              folderModel: root.folderModel
                                                          })
                    selector.pageCompleted.connect(function(page) {
                        page.folderSelected.connect(function(folderId, folderName) {
                            pageStack.pop()
                            root.parentFolderName = folderName
                            root.parentFolderId = folderId
                        })
                    })

                }
            }
        }
        VerticalScrollDecorator {}
    }
}
