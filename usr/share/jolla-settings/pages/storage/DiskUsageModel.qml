import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.systemsettings 1.0
import Nemo.FileManager 1.0 as FileManager

ListModel {
    id: diskUsageModel

    property string storageType
    property real total
    property alias working: du.working

    property var items: ([])
    property var knownItems: ([
        {
            //% "Other user data"
            label: qsTrId("settings_about-li-disk_usage-other_user_data"),
            path: StandardPaths.home,
            storageType: 'user',
            position: 0
        },
        {
            //% "Pictures"
            label: qsTrId("settings_about-li-disk_usage-pictures"),
            path: StandardPaths.pictures,
            storageType: 'user',
            position: 0,
            dBusService: "com.jolla.gallery",
            dBusPath: "/com/jolla/gallery/ui",
            dBusInterface: "com.jolla.gallery.ui",
            dBusMethod: "showPhotos"
        },
        {
            //% "Videos"
            label: qsTrId("settings_about-li-disk_usage-videos"),
            path: StandardPaths.videos,
            storageType: 'user',
            position: 0,
            dBusService: "com.jolla.gallery",
            dBusPath: "/com/jolla/gallery/ui",
            dBusInterface: "com.jolla.gallery.ui",
            dBusMethod: "showVideos"
        },
        {
            //% "Music"
            label: qsTrId("settings_about-li-disk_usage-music"),
            path: StandardPaths.music,
            storageType: 'user',
            position: 0,
            dBusService: "com.jolla.mediaplayer",
            dBusPath: "/com/jolla/mediaplayer/ui",
            dBusInterface: "com.jolla.mediaplayer.ui",
            dBusMethod: "activateWindow",
            dBusArgument: "dummy", // activateWindow is used by libcontentaction, which always requires 1 argument
            pathAllowed: true
        },
        {
            //% "Documents"
            label: qsTrId("settings_about-li-disk_usage-documents"),
            path: StandardPaths.documents,
            storageType: 'user',
            position: 0,
            dBusService: "org.sailfishos.Office",
            dBusPath: "/org/sailfishos/office/ui",
            dBusInterface: "org.sailfishos.Office.ui",
            dBusMethod: "activateWindow",
            pathAllowed: true
        },
        {
            //% "Downloads"
            label: qsTrId("settings_about-li-disk_usage-downloads"),
            path: StandardPaths.download,
            storageType: 'user',
            position: 0,
            pathAllowed: true
        },
        {
            //% "Android™ apps"
            label: qsTrId("settings_about-li-disk_usage-android_apps"),
            path: ':apkd:app',
            storageType: 'user',
            position: 0,
            androidDataDirectory: true
        },
        {
            //% "Android™ app data files"
            label: qsTrId("settings_about-li-disk_usage-android_app_data_files"),
            path: ':apkd:data',
            storageType: 'user',
            position: 0,
            androidDataDirectory: true
        },
        {
            //% "Android™ storage"
            label: qsTrId("settings_about-li-disk_usage-android_storage"),
            path: StandardPaths.home + '/android_storage/',
            storageType: 'user',
            position: 0,
            androidDataDirectory: true,
            pathAllowed: true
        },
        {
            //: %1 is operating system name
            //% "%1 and other files"
            label: qsTrId("settings_about-li-disk_usage-sailfish_os")
                .arg(aboutSettings.operatingSystemName),
            path: '/',
            storageType: 'system',
            position: 0
        },
        {
            //% "Android™ runtime"
            label: qsTrId("settings_about-li-disk_usage-android_runtime"),
            path: ':apkd:runtime',
            storageType: 'system',
            position: 0,
            androidDataDirectory: true
        },
        {
            //: %1 is operating system name without OS suffix
            //% "%1 apps"
            label: qsTrId("settings_about-li-disk_usage-sailfish_apps")
                .arg(aboutSettings.baseOperatingSystemName),
            path: ':rpm:harbour-*',
            storageType: 'system',
            position: 0,
            dBusService: "com.jolla.jollastore",
            dBusPath: "/StoreClient",
            dBusInterface: "com.jolla.jollastore",
            dBusMethod: "openInstalled"
        },
        {
            //: %1 is operating system name without OS suffix
            //% "%1 SDK"
            label: qsTrId("settings_about-li-sailfish_sdk")
                .arg(aboutSettings.baseOperatingSystemName),
            path: '/opt/sdk/',
            storageType: 'system',
            pathAllowed: true
        },
        {
            //% "Core dumps"
            label: qsTrId("settings_about-li-core_dumps"),
            path: '/var/cache/core-dumps/',
            storageType: 'system'
        },
        {
            //% "System logs"
            label: qsTrId("settings_about-li-system_logs"),
            path: '/var/log/',
            storageType: 'system',
        },
        {
            //% "Debug info"
            label: qsTrId("settings_about-li-debug_info"),
            path: ':rpm:*-debuginfo',
            storageType: 'system',
        }
    ])

    Component.onCompleted: {
        // Filter known items based on which storage type is selected
        items = knownItems.filter(function (item) {
            if (!!item.androidDataDirectory && !androidSupport.dataDirectoriesVisible) {
                return false
            }

            return (item.storageType === storageType || storageType === 'mass')
        })

        items.forEach(function (item) {
            item.bytes = 0
            diskUsageModel.append(item)
        })
    }

    function refresh() {
        du.calculate(diskUsageModel.items.map(function (item) { return item.path }),
                  function (usage) {
            var i, j, bytes

            var total = 0
            for (i=0; i<diskUsageModel.count; i++) {
                bytes = usage[diskUsageModel.get(i).path]
                diskUsageModel.setProperty(i, 'bytes', bytes)
                diskUsageModel.setProperty(i, 'position', total)
                total += bytes
            }
            diskUsageModel.total = total
        })
    }

    property QtObject _du: FileManager.DiskUsage { id: du }

    property AndroidSupport androidSupport: AndroidSupport {}

    property AboutSettings aboutSettings: AboutSettings {}
}
