import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
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
    property bool busy

    property AccountModel cloudAccountModel: AccountModel {
        filterType: AccountModel.ServiceTypeFilter
        filter: "storage"
    }

    signal memoryCardMounted

    function refresh() {
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

    property EncryptionUnlocker encryptionUnlocker: EncryptionUnlocker {}

    property Instantiator _externalPartitions: Instantiator {
        model: PartitionModel {
            id: partitions

            storageTypes: PartitionModel.External | PartitionModel.ExcludeParents
            onExternalStoragesPopulatedChanged: root.refresh()
            onMountError: busy = false
            onUnlockError: busy = false

            Component.onCompleted: if (externalStoragesPopulated) root.refresh()
        }

        QtObject {
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
            onPathChanged: {
                refresh()
                busy = false
                if (path) memoryCardMounted()
            }
        }
    }

    function _addCloudAccounts() {
        for (var i=0; i<cloudAccountModel.count; i++) {
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
                "path": ""
            }
            append(props)
        }
    }

    function _addDrives() {
        for (var i = 0; i < _externalPartitions.count; ++i) {
            var storageData = _externalPartitions.objectAt(i)
            append(storageData)
        }
    }
}
