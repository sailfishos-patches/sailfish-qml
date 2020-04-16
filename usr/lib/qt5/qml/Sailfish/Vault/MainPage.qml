import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import Sailfish.Vault 1.0
import Nemo.DBus 2.0
import org.nemomobile.configuration 1.0

Page {
    id: root

    function backupToCloudAccount(accountId) {
        console.log("Trigger cloud backup operation to account", accountId)
        showDialog({"backupMode": true, "cloudAccountId": accountId})
    }

    function restoreFromCloudAccount(accountId, filePath) {
        console.log("Trigger cloud restore operation from account", accountId, filePath)
        showDialog({"backupMode": false, "cloudAccountId": accountId, "fileToRestore": filePath})
    }

    function backupToDir(path) {
        console.log("Trigger backup to directory", path)
        showDialog({"backupMode": true, "backupDir": path})
    }

    function restoreFromFile(path) {
        console.log("Trigger restore from file", path)
        showDialog({"backupMode": false, "fileToRestore": path})
    }

    function showDialog(parameters) {
        parameters.unitListModel = root._unitListModel
        var obj = pageStack.animatorPush(Qt.resolvedUrl("NewBackupRestoreDialog.qml"), parameters)
        obj.pageCompleted.connect(function(dialog) {
            dialog.operationFinished.connect(function(successful) {
                if (successful) {
                    // if accounts were restored, the available storages will have changed

                    // If a backup was done, need to update the last created backup info display;
                    // if a restore was done, the accounts will have changed.
                    contentLoader.item.refreshStoragePickers()
                    if (!dialog.backupMode) {
                        _storageListModel.refresh()
                    }
                }
            })
        })
    }

    property UnitListModel _unitListModel: UnitListModel {}
    property BackupRestoreStorageListModel _storageListModel: BackupRestoreStorageListModel {}
    property bool _cloudStorageAccountServiceAvailable: backupUtils.checkCloudAccountServiceAvailable()

    Component.onCompleted: {
        _unitListModel.loadVaultUnits(BackupRestoreUnitReader.readUnits())
    }

    BusyIndicator {
        id: pageBusy
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: contentLoader.status !== Loader.Ready
    }

    BackupUtils {
        id: backupUtils
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: header.height + contentLoader.height + Theme.paddingLarge

        VerticalScrollDecorator {}

        PageHeader {
            id: header
            //% "Backup"
            title: qsTrId("vault-he-backup")
        }

        Loader {
            id: contentLoader
            opacity: 1 - pageBusy.opacity
            anchors.top: header.bottom
            width: parent.width
            sourceComponent: root._storageListModel.ready
                             ? (root._storageListModel.count > 0 ? mainContentComponent : placeholderContentComponent)
                             : null
        }
    }

    Component {
        id: placeholderContentComponent

        Column {
            width: parent ? parent.width : Screen.width
            spacing: Theme.paddingLarge

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - x*2
                font.family: Theme.fontFamilyHeading
                font.pixelSize: Theme.fontSizeExtraLarge
                wrapMode: Text.Wrap
                color: Theme.highlightColor

                //: No memory card or cloud account available for doing system backup
                //% "There's no memory card or cloud storage account"
                text: qsTrId("vault-la-no_memory_card_or_cloud")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - x*2
                height: implicitHeight + Theme.paddingLarge
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.highlightColor
                textFormat: Text.PlainText

                //% "Please insert a micro SD card and try again. Always use a dedicated card for storing your backups and keep it in a safe place."
                text: qsTrId("vault-la-insert_micro_sd_and_try_again")
            }

            Label {
                visible: root._cloudStorageAccountServiceAvailable
                x: Theme.horizontalPageMargin
                width: parent.width - x*2
                height: implicitHeight + Theme.paddingLarge
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.highlightColor
                textFormat: Text.PlainText

                //% "Alternatively, create a storage account with a third party service to safely store your backed up data."
                text: qsTrId("vault-la-add_cloud_storage_account")
            }

            Button {
                visible: root._cloudStorageAccountServiceAvailable
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: settingsUi.call("showAccounts", [])

                //% "Add account"
                text: qsTrId("vault-bt-add_account")
            }

            DBusInterface {
                id: settingsUi
                service: "com.jolla.settings"
                path: "/com/jolla/settings/ui"
                iface: "com.jolla.settings.ui"
            }
        }
    }

    Component {
        id: mainContentComponent

        Column {
            id: mainContent

            function refreshStoragePickers() {
                backupStoragePicker.refresh()
                restoreStoragePicker.refresh()
            }

            width: parent ? parent.width : Screen.width

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

            BackupRestoreStoragePicker {
                id: backupStoragePicker
                backupMode: true
                storageListModel: root._storageListModel
                height: implicitHeight + Theme.paddingLarge
            }

            Item {
                width: parent.width
                height: Math.max(storageBusyIndicator.height, actionButton.height)

                BusyIndicator {
                    id: storageBusyIndicator
                    anchors.horizontalCenter: parent.horizontalCenter
                    running: _storageListModel.busy
                }

                Button {
                    id: actionButton

                    anchors.horizontalCenter: parent.horizontalCenter
                    enabled: (backupStoragePicker.selectionValid
                              || !backupStoragePicker.selectedStorageMounted
                              || backupStoragePicker.selectedStorageLocked)
                             && !storageBusyIndicator.running
                    opacity: 1 - storageBusyIndicator.opacity

                    text: {
                        if (backupStoragePicker.selectedStorageMounted) {
                            //: Start process of backing up data
                            //% "Backup"
                            return qsTrId("vault-bt-backup")
                        } else if (backupStoragePicker.selectedStorageLocked) {
                            //: SD-card but it is locked (encryption is not yet opened)
                            //% "Unlock"
                            return qsTrId("vault-bt-unlock")
                        }

                        //: SD-card but it is not mounted.
                        //% "Mount"
                        return qsTrId("vault-bt-mount")
                    }

                    onClicked: {
                        var data
                        if (backupStoragePicker.selectedStorageLocked) {
                            data = backupStoragePicker.activeItem()
                            _storageListModel.unlock(data.devPath)
                        } else if (!backupStoragePicker.selectedStorageMounted) {
                            data = backupStoragePicker.activeItem()
                            _storageListModel.mount(data.devPath)
                        } else if (backupStoragePicker.cloudAccountId > 0) {
                            root.backupToCloudAccount(backupStoragePicker.cloudAccountId)
                        } else if (backupStoragePicker.memoryCardPath.length > 0) {
                            root.backupToDir(backupStoragePicker.memoryCardPath)
                        } else {
                            console.log("Internal error, invalid storage type!")
                        }
                    }
                }
            }

            Item {
                width: 1
                height: Theme.paddingLarge * 2
            }

            SectionHeader {
                //: Header for data restore section
                //% "Restore device"
                text: qsTrId("vault-la-restore_device")
            }

            BackupRestoreStoragePicker {
                id: restoreStoragePicker

                backupMode: false
                storageListModel: root._storageListModel
                height: implicitHeight + Theme.paddingLarge
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: restoreStoragePicker.selectionValid && restoreStoragePicker.fileToRestore.length > 0

                //: Start process of restoring data from backup
                //% "Restore"
                text: qsTrId("vault-bt-restore")

                onClicked: {
                    if (restoreStoragePicker.cloudAccountId > 0) {
                        root.restoreFromCloudAccount(restoreStoragePicker.cloudAccountId, restoreStoragePicker.fileToRestore)
                    } else if (restoreStoragePicker.fileToRestore.length > 0) {
                        root.restoreFromFile(restoreStoragePicker.fileToRestore)
                    } else {
                        console.log("Internal error, invalid storage type!")
                    }
                }
            }
        }
    }
}
