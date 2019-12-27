import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.FileManager 1.0 as FileManager

FileManager.DirectoryPage {
    id: directoryPage

    property Item parentPage
    property QtObject partition

    readonly property int mountStatus: partition ? partition.status : PartitionModel.Unmounted

    initialPath: partition ? partition.mountPath : ""
    mounting: mountStatus == PartitionModel.Mounting || mountStatus == PartitionModel.Unmounting
    showNewFolder: !partition || partition.status === PartitionModel.Mounted

    onPartitionChanged: {
        if (!partition && parentPage && status == PageStatus.Active) {
            pageStack.pop(parentPage)
        }
    }

    onMountStatusChanged: {
        if (partition && partition.status == PartitionModel.Unmounting) {
            pageStack.pop(parentPage)
        } else if (mountStatus == PartitionModel.Mounted) {
            refresh()
        }
    }
}
