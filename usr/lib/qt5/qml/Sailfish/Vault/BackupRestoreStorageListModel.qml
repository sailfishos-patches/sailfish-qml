import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import org.nemomobile.systemsettings 1.0

ListModel {
    id: root

    readonly property int storageTypeInvalid: 0
    readonly property int storageTypeMemoryCard: 1
    readonly property int storageTypeCloud: 2
    readonly property bool ready: partitions.externalStoragesPopulated

    property AccountModel cloudAccountModel: AccountModel {
        filterType: AccountModel.ServiceTypeFilter
        filter: "storage"
    }

    function refresh() {
        clear()
        _addCloudAccounts()
        _addDrives()
    }

    property Instantiator _externalPartitions: Instantiator {
        model: PartitionModel {
            id: partitions

            storageTypes: PartitionModel.External | PartitionModel.ExcludeParents
            onExternalStoragesPopulatedChanged: root.refresh()

            Component.onCompleted: if (externalStoragesPopulated) root.refresh()
        }

        QtObject {
            property int type: storageTypeMemoryCard
            property int accountId: 0
            property string name: bytesAvailable > 0
                                 //: the parameter is the capacity of the memory card, e.g. "4.2 GB"
                                 //% "Memory card %1"
                               ? qsTrId("vault-la-memory_card_with_size").arg(Format.formatFileSize(bytesAvailable))
                                 //% "Memory card"
                               : qsTrId("vault-la-memory_card")
            property string path: mountPath
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
            if (storageData.path)
                append(storageData)
        }
    }
}
