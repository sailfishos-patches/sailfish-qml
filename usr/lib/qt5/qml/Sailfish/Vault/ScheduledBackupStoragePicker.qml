/****************************************************************************************
**
** Copyright (c) 2020 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************************/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Vault 1.0
import com.jolla.settings.accounts 1.0

ComboBox {
    id: root

    property var storageListModel

    property int _pendingAccountSelection

    signal createAccount()
    signal storageClicked(int selectedAccountId)

    //: Select an account for automatic backups
    //% "Automatically back up to"
    label: qsTrId("vault-la-automatically_back_up_to")
    automaticSelection: false
    currentIndex: -1

    function selectAccountId(accountId) {
        for (var i = 0; i < storageRepeater.count; ++i) {
            var item = storageRepeater.itemAt(i)
            if (item.accountId === accountId) {
                root.currentIndex = i + 1
                root.storageClicked(item.accountId)
                return true
            }
        }
        _pendingAccountSelection = accountId
        return false
    }

    function _accountDelegateLoaded(index) {
        if (root._pendingAccountSelection === 0) {
            if (currentIndex < 0) {
                // Select 'none' by default until further accounts are loaded
                root.currentIndex = 0
            }
            return
        }

        var item = storageRepeater.itemAt(index)
        if (item.accountId > 0 && item.accountId === _pendingAccountSelection) {
            root.currentIndex = index + 1
            root.storageClicked(item.accountId)
            _pendingAccountSelection = 0
        }
    }

    menu: ContextMenu {
        MenuItem {
            //: Indicates that user has not selected an account for automatic backup
            //% "None"
            text: qsTrId("vault-la-none")

            onClicked: {
                root.currentIndex = 0
                root.storageClicked(0)
            }
        }

        Repeater {
            id: storageRepeater

            model: root.storageListModel

            MenuItem {
                readonly property int accountId: model.accountId

                text: model.name
                visible: model.accountId > 0

                Component.onCompleted: root._accountDelegateLoaded(model.index)
                onClicked: {
                    root.currentIndex = model.index + 1
                    root.storageClicked(model.accountId)
                }
            }
        }

        MenuItem {
            text: BackupUtils.addCloudAccountText
            color: Theme.highlightColor

            onClicked: {
                root.createAccount()
            }
        }
    }

    description: root.currentIndex === 0
                   //% "No automatic backups scheduled"
                 ? qsTrId("vault-la-no_automatic_backups_scheduled")
                 : BackupUtils.cloudBackupDescription(storageListModel.cloudBackupUnits.join(Format.listSeparator))
}
