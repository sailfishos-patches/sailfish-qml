/*
 * Copyright (c) 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import com.jolla.settings.accounts 1.0
import Nemo.Email 0.1

Column {
    property int accountId
    property bool active
    property int maxFolders: 6
    readonly property string policy: comboBox.currentItem.policy
    property bool _autoScroll
    opacity: enabled ? 1.0 : Theme.opacityLow

    id: root

    function setPolicy(newPolicy) {
        var newIndex = 0
        if (newPolicy) {
            for (var i = 0; i < comboBox.menu.children.length; i++) {
                if (comboBox.menu.children[i].policy === newPolicy) {
                    newIndex = i
                    break
                }
            }
        }

        if (newIndex !== comboBox.currentIndex) {
            _autoScroll = false
            comboBox.currentIndex = newIndex
        }
    }

    ComboBox {
        id: comboBox
        readonly property bool isManualPolicy: currentIndex == 2

        visible: active
        //: Combobox title for syncing email folders
        //% "Synced folders"
        label: qsTrId("settings-accounts-la-sync_folders")
        menu: ContextMenu {
            MenuItem {
                readonly property string policy: "inbox"
                //: Syncing email folders option
                //% "Inbox only"
                text: qsTrId("settings-accounts-me-inbox_only")
                onClicked: _autoScroll = true
            }
            MenuItem {
                readonly property string policy: "inbox-and-subfolders"
                //: Syncing email folders option
                //% "Inbox and subfolders"
                text: qsTrId("settings-accounts-me-inbox_all")
                onClicked: _autoScroll = true
            }
            MenuItem {
                readonly property string policy: "follow-flags"
                //: Syncing email folders option (equivalent to "select folders to sync")
                //% "Custom"
                text: qsTrId("settings-accounts-me-custom_folders")
                onClicked: _autoScroll = true
            }
        }
    }

    Item {
        width: parent.width
        height: _manualVisible ? loader.height : 0
        opacity: _manualVisible ? 1.0 : 0.0
        VerticalAutoScroll.keepVisible: animation.running && _autoScroll
        clip: animation.running

        readonly property bool _manualVisible: comboBox.isManualPolicy && root.active

        Behavior on height { NumberAnimation { id: animation; duration: 200; easing.type: Easing.InOutQuad } }
        Behavior on opacity { FadeAnimator {} }

        Loader {
            id: loader
            active: parent._manualVisible || animation.running
            width: parent.width
            sourceComponent: Column {
                readonly property bool showFolders: maxFolders < 0 || folderListView.folderCount <= maxFolders

                FolderListView {
                    id: folderListView
                    accountId: root.accountId
                    visible: showFolders
                }

                BackgroundItem {
                    id: configureFolders
                    visible: !showFolders
                    height: Theme.itemSizeMedium
                    onClicked: pageStack.animatorPush('FolderSyncPage.qml', { accountId: accountId })

                    Icon {
                        anchors {
                            right: parent.right
                            rightMargin: Theme.horizontalPageMargin
                            verticalCenter: parent.verticalCenter
                        }
                        source: "image://theme/icon-m-add"
                    }

                    Column {
                        id: configureFoldersColumn
                        x: Theme.horizontalPageMargin
                        y: Theme.paddingMedium
                        width: parent.width - x

                        Label {
                            width: parent.width - Theme.itemSizeSmall - 2 * Theme.horizontalPageMargin
                            wrapMode: Text.Wrap
                            //: Please simplify to just "Custom folders" for longer translations
                            //% "Custom folders to sync"
                            text: qsTrId("settings_accounts-bu-custom_folders")
                        }
                        Label {
                            readonly property bool foldersSelected : folderListView.syncFolderList.length > 0
                            width: parent.width - Theme.itemSizeSmall - 2 * Theme.horizontalPageMargin
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: configureFolders.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                            truncationMode: foldersSelected ? TruncationMode.Fade : TruncationMode.None
                            wrapMode: foldersSelected ? Text.NoWrap : Text.Wrap
                            text: foldersSelected
                                  ? folderListView.syncFolderList.join(Format.listSeparator)
                                    //: Shown instead of the folder list in case no folders are selected
                                    //% "No folders selected"
                                  : qsTrId("settings_accounts-la-none_selected")
                        }
                    }
                }
            }
        }
    }
}
