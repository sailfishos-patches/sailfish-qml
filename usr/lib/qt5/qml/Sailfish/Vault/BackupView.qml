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
import Connman 0.2
import Nemo.DBus 2.0

Column {
    id: root

    property BackupRestoreStorageListModel storageListModel
    readonly property bool backupRunning: progressItem.busy
    readonly property int scheduledBackupAccountId: backupSettingsItem.cloudAccountId

    signal cloudBackupFinished(var accountId)
    signal fileBackupFinished(var filePath)
    signal createAccount()

    function selectCreatedStorage(accountId) {
        backupSettingsItem.selectAccountId(accountId)
    }

    function _deleteOldBackups(dirPath) {
        // keep the two latest backups
        var fileInfos = BackupUtils.sortedBackupFileInfo(dirPath, BackupUtils.TarArchive, false)
        var files = []
        for (var i = 2; i < fileInfos.length; i++) {
            files.push(dirPath + '/' + fileInfos[i].fileName)
        }
        if (files.length > 0) {
            BackupUtils.removeFiles(files)
        }
    }

    width: parent.width
    bottomPadding: Theme.paddingSmall

    Label {
        x: Theme.horizontalPageMargin
        width: parent.width - x*2
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.highlightColor
        height: implicitHeight + Theme.paddingLarge

        //% "Create a backup to protect your personal data. Use it later to restore your device just the way it was."
        text: qsTrId("vault-la-create_backup_info")
    }

    Column {
        width: parent.width
        height: enabled ? implicitHeight : 0
        spacing: Theme.paddingLarge
        bottomPadding: Theme.paddingLarge + Theme.paddingMedium

        enabled: root.storageListModel.cloudAccountModel.count > 0
                 && networkManagerFactory.instance.state !== ""
                 && networkManagerFactory.instance.state !== "online"
        opacity: enabled ? 1 : 0
        Behavior on opacity { FadeAnimator {} }
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

        onEnabledChanged: {
            if (enabled) {
                connectButton.visible = true
            }
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - Theme.horizontalPageMargin*2
            wrapMode: Text.Wrap
            color: Theme.errorColor
            font.pixelSize: Theme.fontSizeSmall

            //% "Unable to connect. An internet connection is needed to back up to cloud services."
            text: qsTrId("vault-la-unable_to_connect_cloud_internet_connection_needed")
        }

        Button {
            id: connectButton

            anchors.horizontalCenter: parent.horizontalCenter

            //: Connect to internet
            //% "Connect"
            text: qsTrId("vault-bt-connect")

            onClicked: {
                connectionSelector.call('openConnectionNow', 'wifi')
                visible = false
            }
        }

        BusyIndicator {
            anchors.horizontalCenter: parent.horizontalCenter
            height: connectButton.height
            size: BusyIndicatorSize.Medium
            running: parent.enabled && !connectButton.visible
            visible: !connectButton.visible
        }
    }

    BackupSettingsItem {
        id: backupSettingsItem

        storageListModel: root.storageListModel

        onCreateAccount: {
            root.createAccount()
        }
    }

    SectionHeader {
        //: Section for manual backup
        //% "Manual backup"
        text: qsTrId("vault-la-manual_backup")
    }

    Label {
        x: Theme.horizontalPageMargin
        width: parent.width - Theme.horizontalPageMargin*2
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.highlightColor

        //% "Back up now to a cloud account or memory card."
        text: qsTrId("vault-la-back_up_now_to_a_cloud_account_or_memory_card")
    }

    BackupRestoreStoragePicker {
        id: storagePicker

        storageListModel: root.storageListModel
        enabled: !progressItem.busy
    }

    BackupRestoreProgressItem {
        id: progressItem

        operationType: "backup"
        storageListModel: root.storageListModel
        backupStoragePicker: storagePicker

        //: Start process of backing up data
        //% "Back up now"
        actionButtonText: qsTrId("vault-bt-back_up_now")

        onActionButtonClicked: {
            if (storagePicker.cloudAccountId > 0) {
                backupToCloud(storagePicker.cloudAccountId)
            } else if (storagePicker.memoryCardPath.length > 0) {
                var filePath = storagePicker.memoryCardPath
                        + '/' + BackupUtils.newBackupFileName(BackupUtils.TarArchive)
                backupToFile(filePath)
            } else {
                console.warn("Internal error, invalid storage type!")
            }
        }

        onOkButtonClicked: {
            setLiveUpdatesEnabled(true)
        }

        onCloudBackupFinished: {
            root.cloudBackupFinished(accountId)
        }

        onFileBackupFinished: {
            _deleteOldBackups(filePath.substr(0, filePath.lastIndexOf('/')))
            root.fileBackupFinished(filePath)
        }
    }

    NetworkManagerFactory {
        id: networkManagerFactory
    }

    DBusInterface {
        id: connectionSelector

        service: "com.jolla.lipstick.ConnectionSelector"
        path: "/"
        iface: "com.jolla.lipstick.ConnectionSelectorIf"
    }
}
