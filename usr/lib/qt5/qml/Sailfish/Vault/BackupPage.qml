/****************************************************************************************
**
** Copyright (c) 2013 - 2019 Jolla Ltd.
** Copyright (c) 2020 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************************/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Vault 1.0
import Nemo.DBus 2.0
import com.jolla.settings.accounts 1.0

Page {
    id: root

    property alias _storageListModel: storageListModel
    readonly property bool _selectingNewAccount: _newAccountIdToSelect > 0
            && (backupView.scheduledBackupAccountId != _newAccountIdToSelect)
    property int _newAccountIdToSelect
    property bool _waitForSailfishBackupService: true
    property bool _placeholderCreatingAccount

    onStatusChanged: {
        if (status === PageStatus.Active
                && root._newAccountIdToSelect > 0) {
            if (!_placeholderCreatingAccount) {
                backupView.selectCreatedStorage(_newAccountIdToSelect)
            }
            root._newAccountIdToSelect = 0
            _placeholderCreatingAccount = false
        }
    }

    BusyLabel {
        id: pageBusy

        running: !root._storageListModel.ready
                 || _waitForSailfishBackupService
                 || (_selectingNewAccount || selectNewAccountTimer.running)
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: header.height + (placeholder.visible ? placeholder.height : mainContent.height)

        VerticalScrollDecorator {}

        PageHeader {
            id: header

            //% "Backup"
            title: qsTrId("vault-he-backup")
        }

        BackupPlaceholder {
            id: placeholder

            anchors.top: header.bottom
            width: parent.width
            visible: root._storageListModel.ready && root._storageListModel.count === 0
            opacity: 1 - pageBusy.opacity
            enabled: !pageBusy.running

            onCreateAccount: {
                root._placeholderCreatingAccount = true
                accountCreationManager.startAccountCreation()
            }
        }

        Column {
            id: mainContent

            anchors.top: header.bottom
            width: parent.width
            bottomPadding: Theme.paddingLarge
            visible: !placeholder.visible
            opacity: 1 - pageBusy.opacity
            enabled: !pageBusy.running

            BackupView {
                id: backupView

                storageListModel: root._storageListModel

                onCloudBackupFinished: storageListModel.refreshLatestCloudBackup(accountId)
                onFileBackupFinished: storageListModel.refreshLatestFileBackup(filePath)
                onCreateAccount: accountCreationManager.startAccountCreation()
            }

            SectionHeader {
                //: Header for data restore section
                //% "Restore device"
                text: qsTrId("vault-la-restore_device")
                visible: recentBackups.count > 0
            }

            RecentBackupsView {
                id: recentBackups

                storageListModel: root._storageListModel
                enabled: !backupView.backupRunning

                onBackupClicked: {
                    var props = {
                        "cloudAccountId": cloudAccountId,
                        "sourceName": sourceName,
                        "backupInfo": backupInfo,
                        "storageListModel": root._storageListModel
                    }
                    pageStack.animatorPush("Sailfish.Vault.RestorePage", props)
                }
            }
        }
    }

    AccountCreationManager {
        id: accountCreationManager

        serviceFilter: ["storage"]
        endDestination: root
        endDestinationAction: PageStackAction.Pop

        onAccountCreated: {
            root._newAccountIdToSelect = newAccountId
            if (!_placeholderCreatingAccount) {
                backupView.selectCreatedStorage(newAccountId)
            }
        }
    }

    DBusInterface {
        id: sailfishBackup

        service: "org.sailfishos.backup"
        path: "/sailfishbackup"
        iface: "org.sailfishos.backup"

        watchServiceStatus: true

        onStatusChanged: {
            if (status === DBusInterface.Available) {
                // Ensure the service is ready before showing the main page contents on initial
                // page load. The dbus service auto-stops after a timeout, so if it becomes
                // unavailable at other times after the initial page load, that's okay.
                root._waitForSailfishBackupService = false
            }
        }
    }

    Timer {
        id: selectNewAccountTimer

        interval: 3000
        running: (root.status === PageStatus.Activating || root.status === PageStatus.Active)
                 && _selectingNewAccount

        // If the new account can't be selected after a timeout, load the page without
        // selecting it. This could happen if the account's storage service is not enabled.
        onTriggered: {
            if (root._selectingNewAccount) {
                root._newAccountIdToSelect = 0
            }
        }
    }

    BackupRestoreStorageListModel {
        id: storageListModel
    }
}
