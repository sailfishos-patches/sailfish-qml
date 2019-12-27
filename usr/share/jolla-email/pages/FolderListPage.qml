/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1

Page {
    id: folderListPage

    property alias accountKey: folderModel.accountKey

    signal folderClicked(var accessor)
    signal deletingFolder(int id)

    FolderListModel {
        id: folderModel

        onResyncNeeded: {
            emailAgent.retrieveFolderList(accountKey)
        }
    }

    Connections {
        target: emailAgent
        onOnlineFolderActionCompleted: {
            if (!success) {
                emailAgent.retrieveFolderList(accountKey) // refresh folders list in case of error
            }
        }
    }

    SilicaListView {
        anchors.fill: parent
        model: folderModel
        header: PageHeader {
            //: Folder List page title
            //% "Folders"
            title: qsTrId("jolla-email-he-folder_list_title")
        }

        delegate: FolderItem {
            enabled: canHaveMessages
            showUnreadCount: true
            onClicked: folderListPage.folderClicked(folderModel.folderAccessor(index))
            menu: ((canCreateChild || canRename || canMove || canDelete) && !preDeletionTimer.running)
                  ? contextMenuComponent : null
            visible: !preDeletionTimer.running
            Component {
                id: contextMenuComponent
                ContextMenu {
                    MenuItem {
                        visible: canCreateChild
                        //% "New subfolder"
                        text: qsTrId("jolla-email-fi-new_subfolder")
                        onClicked: {
                            pageStack.animatorPush(Qt.resolvedUrl("NewFolderDialog.qml"), {
                                                       parentFolderId: folderId,
                                                       parentFolderName: folderDisplayName,
                                                       folderModel: folderModel
                                                   })
                        }
                    }
                    MenuItem {
                        visible: canRename
                        //% "Rename"
                        text: qsTrId("jolla-email-fi-rename_folder")
                        onClicked: {
                            pageStack.animatorPush(Qt.resolvedUrl("RenameFolderDialog.qml"), {
                                                       folderName: folderName,
                                                       folderId: folderId
                                                   })
                        }
                    }
                    MenuItem {
                        visible: canMove
                        //% "Move"
                        text: qsTrId("jolla-email-fi-move_folder")
                        onClicked: {
                            pageStack.animatorPush(Qt.resolvedUrl("MoveFolderPage.qml"), {
                                                       folderModel: folderModel,
                                                       folderName: model.folderName,
                                                       folderId: model.folderId,
                                                       parentFolderId: model.parentFolderId
                                                   })
                        }
                    }
                    MenuItem {
                        visible: canDelete
                        //% "Delete"
                        text: qsTrId("jolla-email-fi-delete_folder")
                        onClicked: _remove()
                    }
                }
            }
            Timer {
                id: preDeletionTimer
                interval: 3000 // to avoid delegate flicking when remove is executed pretty fast
                repeat: false
            }

            function _remove() {
                remorseDelete(function() {
                    folderListPage.deletingFolder(folderId)
                    preDeletionTimer.start()
                    emailAgent.deleteFolder(folderId)
                })
            }
        }

        PullDownMenu {
            busy: emailAgent.currentSynchronizingAccountId === folderModel.accountKey
            visible: folderModel.supportsFolderActions
            MenuItem {
                //% "Refresh folder list"
                text: qsTrId("jolla-email-folder_list_refresh")
                onClicked: emailAgent.retrieveFolderList(folderModel.accountKey)
            }
            MenuItem {
                //% "New folder"
                text: qsTrId("jolla-email-folder_new")
                visible: folderModel.canCreateTopLevelFolders
                onClicked: {
                    pageStack.animatorPush(Qt.resolvedUrl("NewFolderDialog.qml"), {
                                               parentFolderId: 0,
                                               //: No parent folder
                                               //% "None"
                                               parentFolderName: qsTrId("jolla-email-la-none_folder"),
                                               folderModel: folderModel
                                           })
                }
            }
        }

        VerticalScrollDecorator {}
    }
}
