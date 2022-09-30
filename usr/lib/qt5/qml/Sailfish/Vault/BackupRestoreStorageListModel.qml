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
import Sailfish.Accounts 1.0
import Sailfish.Vault 1.0
import MeeGo.Connman 0.2
import Nemo.DBus 2.0
import org.nemomobile.systemsettings 1.0
import com.jolla.settings.system 1.0

ListModel {
    id: root

    readonly property int storageTypeInvalid: 0
    readonly property int storageTypeMemoryCard: 1
    readonly property int storageTypeCloud: 2
    readonly property bool ready: partitions.externalStoragesPopulated
    readonly property int storageMounted: PartitionModel.Mounted
    readonly property int storageLocked: PartitionModel.Locked
    property var localBackupUnits: _sailfishBackup.localBackupUnits
    property var cloudBackupUnits: _sailfishBackup.cloudBackupUnits
    property bool busy

    property AccountModel cloudAccountModel: AccountModel {
        filterType: AccountModel.ServiceTypeFilter
        filter: "storage"
        filterByEnabled: true

        onCountChanged: {
            _refreshTimer.restart()
        }
    }
    property Timer _refreshTimer: Timer {
        interval: 1
        onTriggered: root.refresh()
    }

    readonly property bool _readyToInit: partitions.externalStoragesPopulated
                                         && _sailfishBackup.status.length > 0
    on_ReadyToInitChanged: {
        if (_readyToInit) {
            _refreshTimer.start()
        }
    }

    signal memoryCardMounted

    function refresh() {
        _refreshTimer.stop()
        clear()
        _addCloudAccounts()
        _addDrives()
    }

    function mount(devicePath) {
        busy = true
        partitions.mount(devicePath)
    }

    function unlock(devicePath) {
        busy = true
        var objectPath = partitions.objectPath(devicePath)
        encryptionUnlocker.unlock(root, objectPath)
    }

    function refreshLatestCloudBackup(accountId) {
        for (var i = 0; i < count; ++i) {
            var data = get(i)
            if (data.accountId === accountId) {
                _refreshCloudBackup(i)
                break
            }
        }
    }

    function refreshLatestFileBackup(filePath) {
        for (var i = 0; i < count; ++i) {
            var data = get(i)
            if (data.path.length > 0 && filePath.indexOf(data.path) === 0) {
                setProperty(i, "latestBackupInfo", _latestFileBackupInfo(data.path))
                break
            }
        }
    }

    function _latestFileBackupInfo(localDir, deviceStatus) {
        var fileInfo
        if (localDir.length > 0) {
            var files = BackupUtils.sortedBackupFileInfo(localDir, BackupUtils.TarArchive, false)
            if (files.length === 0) {
                files = BackupUtils.sortedBackupFileInfo(localDir, BackupUtils.TarArchive, true)
            }
            fileInfo = files[0]
        }
        var latestBackupInfo = {
            "fileName": fileInfo ? fileInfo.fileName : "",
            "fileDir": fileInfo ? fileInfo.fileDir : "",
            "created": fileInfo ? fileInfo.created : undefined,
            "error": _errorForDeviceStatus(localDir, deviceStatus),
            "ready": true
        }
        return latestBackupInfo
    }

    function _errorForDeviceStatus(path, deviceStatus) {
        if (deviceStatus === storageLocked) {
            //% "The memory card is locked."
            return qsTrId("vault-la-cloud-la-memory_card_is_locked")
        } else if (!path) {
            //% "The memory card is not mounted."
            return qsTrId("vault-la-cloud-la-memory_card_not_mounted")
        } else if (!BackupUtils.verifyWritable(path)) {
            //% "The memory card is not writable."
            return qsTrId("vault-la-cloud-la-memory_card_unwritable")
        } else {
             return ""
        }
    }

    property EncryptionUnlocker encryptionUnlocker: EncryptionUnlocker {}

    property Instantiator _externalPartitions: Instantiator {
        model: PartitionModel {
            id: partitions

            storageTypes: PartitionModel.External | PartitionModel.ExcludeParents
            onExternalStoragesPopulatedChanged: if (root.count > 0) root.refresh()
            onMountError: busy = false
            onUnlockError: busy = false
        }

        delegate: QtObject {
            property int type: storageTypeMemoryCard
            property int accountId: 0
            property string devPath: devicePath
            property int deviceStatus: status

            property string name: bytesAvailable > 0
                                 //: the parameter is the capacity of the memory card, e.g. "4.2 GB"
                                 //% "Memory card %1"
                               ? qsTrId("vault-la-memory_card_with_size").arg(Format.formatFileSize(bytesAvailable))
                                 //% "Memory card"
                               : qsTrId("vault-la-memory_card")
            property string path: mountPath
            property var latestBackupInfo: _latestFileBackupInfo(path, model.status)

            onPathChanged: {
                latestBackupInfo = _latestFileBackupInfo(path, model.status)
                refresh()
                busy = false
                if (path) memoryCardMounted()
            }
        }
    }

    property AccountManager _accountManager: AccountManager { }

    function _addCloudAccounts() {
        if (_sailfishBackup.status.length === 0) {
            return
        }

        for (var i = 0; i < cloudAccountModel.count; i++) {
            var data = cloudAccountModel.get(i)

            //: The account type and account name, e.g.: "Dropbox (username)"
            //% "%1 (%2)"
            var name = data.accountUserName
                    ? qsTrId("vault-he-cloud_account_name").arg(data.providerDisplayName).arg(data.accountUserName)
                    : data.providerDisplayName
            var props = {
                "type": storageTypeCloud,
                "name": name,
                "accountId": data.accountId,
                "path": "",
                "devPath": "",
                "latestBackupInfo": {}
            }
            append(props)

            _refreshCloudBackup(count - 1)
        }
    }

    function _addDrives() {
        if (!partitions.externalStoragesPopulated) {
            return
        }
        for (var i = 0; i < _externalPartitions.count; ++i) {
            var storageData = _externalPartitions.objectAt(i)
            if (storageData) {
                append(storageData)
            }
        }
    }

    function _findAccount(accountId) {
        for (var i = 0; i < count; ++i) {
            if (get(i).accountId === accountId) {
                return i
            }
        }
        return -1
    }

    function _refreshCloudBackup(index) {
        var data = get(index)
        if (data && data.accountId > 0) {
            var latestBackupInfo = {
                "fileName": "",
                "fileDir": "",
                "created": undefined,
                "error": "",
                "ready": true
            }
            if (_accountManager.credentialsNeedUpdate(data.accountId)) {
                //: Error shown when an account is not available because user has not signed in
                //% "Account not signed in"
                latestBackupInfo.error = qsTrId("vault-la-account_not_signed_in")
            } else if (_networkManagerFactory.instance.state === "online") {
                latestBackupInfo.ready = false
                _sailfishBackup.listCloudBackups(data.accountId)
            } else {
                latestBackupInfo.error = BackupUtils.cloudConnectErrorText
            }
            setProperty(index, "latestBackupInfo", latestBackupInfo)
        }
    }

    property var _sailfishBackup: DBusInterface {
        property string status
        property var localBackupUnits: []
        property var cloudBackupUnits: []
        property var _pendingListCalls: ({})

        function listCloudBackups(accountId) {
            _pendingListCalls[accountId] = true
            call("listCloudBackups", [accountId, true])
        }

        function listCloudBackupsFinished(accountId, fileNames, success) {
            if (!_pendingListCalls[accountId]) {
                return
            }
            delete _pendingListCalls[accountId]

            var rowIndex = root._findAccount(accountId)
            if (rowIndex < 0) {
                return
            }

            var latestBackupInfo = {
                "fileName": "",
                "fileDir": "",
                "created": undefined,
                "error": "",
                "ready": true
            }

            if (success) {
                var fileInfoList = BackupUtils.sortedBackupFileInfo(fileNames, BackupUtils.TarGzipArchive, false)
                if (fileInfoList.length === 0) {
                    fileInfoList = BackupUtils.sortedBackupFileInfo(fileNames, BackupUtils.TarGzipArchive, true)
                }
                var fileInfo = fileInfoList[0]
                latestBackupInfo.fileName = fileInfo ? fileInfo.fileName : ""
                latestBackupInfo.fileDir = fileInfo ? fileInfo.fileDir : ""
                latestBackupInfo.created = fileInfo ? fileInfo.created : undefined
            } else {
                latestBackupInfo.error = BackupUtils.cloudConnectErrorText
            }

            set(rowIndex, {"latestBackupInfo": latestBackupInfo})
        }

        service: "org.sailfishos.backup"
        path: "/sailfishbackup"
        iface: "org.sailfishos.backup"

        propertiesEnabled: true
        signalsEnabled: true
    }

    property NetworkManagerFactory _networkManagerFactory: NetworkManagerFactory {}

    property Connections _networkManagerConnection: Connections {
        target: _networkManagerFactory.instance
        onStateChanged: {
            for (var i = 0; i < root.count; ++i) {
                _refreshCloudBackup(i)
            }
        }
    }

    dynamicRoles: true
}
