/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1

Page {
    readonly property int selectionCount: selectionModel ? selectionModel.selectedMessageCount : 0
    // these two for move to page
    property int accountId
    property int folderId
    property bool actionInProgress
    property bool showMove: accountId != 0
    property MessageRemorsePopup removeRemorse
    property EmailMessageListModel selectionModel

    onStatusChanged: {
        if (status === PageStatus.Deactivating) {
            if (!actionInProgress) {
                selectionModel.deselectAllMessages()
            }
        } else if (status === PageStatus.Active) {
            // we want to have all messages available here for the mass operations
            selectionModel.limit = 0
        }
    }

    function _deleteClicked() {
        actionInProgress = true
        removeRemorse.selectionModel = selectionModel
        removeRemorse.startDeleteSelectedMessages()
        pageStack.pop()
    }

    function _moveClicked() {
        actionInProgress = true
        pageStack.animatorReplace(Qt.resolvedUrl("MoveToPage.qml"), {
                                      messageModel: selectionModel,
                                      accountKey: accountId,
                                      currentFolder: folderId
                                  })
    }

    SilicaListView {
        clip: dockedPanel.expanded

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: dockedPanel.top
        }

        header: PageHeader {
            title: selectionCount ? //: Selected messages
                                    //% "Selected %n"
                                    qsTrId("jolla-email-he-select_messages", selectionCount)
                                  : //: Message selection header, no currently selected messages
                                    //% "Selected"
                                    qsTrId("jolla-email-he-zero_selected_messages")
        }

        model: selectionModel

        section {
            property: 'timeSection'

            delegate: SectionHeader {
                text: Format.formatDate(section, Formatter.TimepointSectionRelative)
                height: text === "" ? 0 : implicitHeight + Theme.itemSizeSmall / 2
                horizontalAlignment: Text.AlignHCenter
            }
        }

        delegate: MessageItem {
            function _toggleSelection() {
                if (model.selected) {
                    selectionModel.deselectMessage(model.index)
                } else {
                    selectionModel.selectMessage(model.index)
                }
            }

            menu: undefined // actions in docked panel
            selectMode: true

            onClicked: _toggleSelection()
            onPressAndHold: _toggleSelection()
        }

        PullDownMenu {
            busy: app.syncInProgress

            MenuItem {
                //: Deselect all messages
                //% "Deselect all"
                text: qsTrId("jolla-email-me-deselect_all_messages")
                visible: selectionCount
                onClicked: selectionModel.deselectAllMessages()
            }

            MenuItem {
                //: Select all messages
                //% "Select all"
                text: qsTrId("jolla-email-me-select_all_messages")
                visible: selectionModel.count > 0 && selectionCount < selectionModel.count
                onClicked: selectionModel.selectAllMessages()
            }
        }

        VerticalScrollDecorator {}
    }

    DockedPanel {
        id: dockedPanel
        width: parent.width
        height: Theme.itemSizeLarge
        dock: Dock.Bottom
        open: selectionCount

        Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            source: "image://theme/graphic-gradient-edge"
        }
        Row {
            Item {
                width: moveIcon.visible ? dockedPanel.width/3 : dockedPanel.width/2
                height: Theme.itemSizeLarge
                IconButton {
                    anchors.centerIn: parent
                    icon.source: "image://theme/icon-m-delete"
                    onClicked: _deleteClicked()
                }
            }
            Item {
                width: moveIcon.visible ? dockedPanel.width/3 : dockedPanel.width/2
                height: Theme.itemSizeLarge
                IconButton {
                    anchors.centerIn: parent
                    icon.source: selectionModel.unreadMailsSelected ? "image://theme/icon-m-mail-open" : "image://theme/icon-m-mail"
                    onClicked: {
                        if (selectionModel.unreadMailsSelected) {
                            selectionModel.markAsReadSelectedMessages()
                        } else {
                            selectionModel.markAsUnReadSelectedMessages()
                        }
                    }
                }
            }
            Item {
                id: moveIcon
                visible: showMove
                width: dockedPanel.width/3
                height: Theme.itemSizeLarge
                IconButton {
                    anchors.centerIn: parent
                    icon.source: "image://theme/icon-m-message-forward"
                    onClicked: _moveClicked()
                }
            }
        }
    }
}
