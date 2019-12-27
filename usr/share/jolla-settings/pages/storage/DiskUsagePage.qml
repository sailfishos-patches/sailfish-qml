import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import org.nemomobile.dbus 2.0

Page {
    id: diskUsagePage

    property var colors: ["#458DBA", "#B3609B", "#BFA058", "#2EA3A1", "#B37948", "#519C3F", "#B35F54", "#8CA646", "#506FC7"]

    property int storageType: partition ? partition.storageType : Partition.Invalid
    property real usedSpace: partition ? partition.bytesTotal - partition.bytesAvailable : 0
    property real totalSpace: partition ? partition.bytesTotal : 0
    property string path: {
        if (partition) {
            if (partition.mountPath == "/home") {
                return StandardPaths.home
            } else if (partition.mountPath == "/" && storageType == PartitionModel.Mass) {
                return StandardPaths.home
            } else {
                return partition.mountPath
            }
        }
        return ""
    }
    property string title
    property bool initialized

    property Item parentPage
    property QtObject partition

    // Note that partition is QQmlDMAbstractItemModelData e.i. can be used to access
    // roles of a PartitionModel.
    readonly property int partitionStatus: partition ? partition.status : PartitionModel.Unmounted
    onPartitionStatusChanged: {
        if (partitionStatus == PartitionModel.Unmounting) {
            pageStack.pop(diskUsagePage)
        }
    }

    // Avoid "ReferenceError: dBusArgument is not defined" errors
    // that happen if no disk usage ListModel elements define such roles
    property var dBusService
    property var dBusArgument: []

    onPartitionChanged: {
        if (!partition && parentPage) {
            pageStack.pop(parentPage)
        }
    }


    onStatusChanged: {
        if (status === PageStatus.Active) {
            diskUsageModel.refresh()

            if (partition) {
                partition.partitionModel.refresh(partition.index)
            }

            if (!partition && parentPage) {
                pageStack.pop(parentPage)
            }
        }
    }

    Connections {
        target: Qt.application
        onActiveChanged: {
            var refresh = (Qt.application.active && diskUsagePage.status === PageStatus.Active)
            if (refresh) {
                diskUsageModel.refresh()
            }
        }
    }

    SilicaListView {
        anchors.fill: parent
        header: Column {
            width: parent.width
            spacing: Theme.paddingMedium
            PageHeader {
                title: diskUsagePage.title
            }
            DiskUsageHeader {
                model: diskUsageModel
                usedSpace: diskUsagePage.usedSpace
                totalSpace: diskUsagePage.totalSpace
                initialized: diskUsagePage.initialized
            }
            Item {
                width: 1
                height: Theme.paddingMedium
            }
        }
        footer: Item { width: 1; height: Theme.paddingLarge }

        PullDownMenu {
            id: pulleyMenu

            visible: !diskUsageModel.working || storageType !== "system"

            property bool actionSelected

            onActiveChanged: {
                if (!active && actionSelected) {
                    actionSelected = false
                    diskUsageModel.refresh()
                }
            }

            MenuItem {
                //% "File manager"
                text: qsTrId("settings_about-me-file_manager")
                //% "User data"
                onClicked: pageStack.animatorPush("DirectoryPage.qml", { initialPath: diskUsagePage.path, title: qsTrId("settings_storage-he-user_data") })
                visible: diskUsageModel.storageType == "user" || diskUsageModel.storageType == "mass"
            }

            MenuItem {
                //% "Update"
                text: qsTrId("settings_about-me-update")
                onClicked: pulleyMenu.actionSelected = true
                enabled: !diskUsageModel.working
            }
        }

        model: DiskUsageModel {
            id: diskUsageModel
            onWorkingChanged: if (!working) initialized = true

            storageType: {
                switch (diskUsagePage.storageType) {
                case PartitionModel.System: return "system"
                case PartitionModel.User: return "user"
                case PartitionModel.Mass: return "mass"
                case PartitionModel.External: return "card"
                default: return ""
                }
            }
        }

        delegate: DiskUsageListItem {
            bytes: model.bytes
            total: diskUsageModel.total
            enabled: dBusService !== undefined || (model.hasOwnProperty("pathAllowed") && model.pathAllowed)
            onClicked: {
                if (dBusService) {
                    dbusInterface.service = dBusService
                    dbusInterface.path = dBusPath
                    dbusInterface.iface = dBusInterface
                    dbusInterface.call(dBusMethod, dBusArgument, function() { /* success */ }, function() { openPath() } )
                } else {
                    openPath()
                }
            }
            function openPath() {
                if (pathAllowed) {
                    pageStack.animatorPush("DirectoryPage.qml", { initialPath: path, title: path.replace(StandardPaths.home + "/", "") })
                }
            }
        }

        VerticalScrollDecorator {}
    }
    DBusInterface {
        id: dbusInterface
    }
}
