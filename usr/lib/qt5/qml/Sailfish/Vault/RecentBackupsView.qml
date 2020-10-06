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
import Nemo.DBus 2.0

Column {
    id: root

    property alias storageListModel: recentBackupsRepeater.model
    property alias count: recentBackupsRepeater.count
    property var today: new Date()

    signal backupClicked(string sourceName, int cloudAccountId, var backupInfo)

    width: parent.width

    Label {
        visible: recentBackupsRepeater.count > 0
        x: Theme.horizontalPageMargin
        width: parent.width - Theme.horizontalPageMargin*2
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.highlightColor

        //: Label above the name of the backup that will be restored to the device.
        //% "You can restore your device from these previous backups:"
        text: qsTrId("vault-la-restore_your_device_description")
    }

    Repeater {
        id: recentBackupsRepeater

        delegate: ListItem {
            id: backupInfoDelegate

            readonly property string fileName: !!model.latestBackupInfo ? model.latestBackupInfo.fileName || "" : ""
            property string logFilePath

            width: root.width
            contentHeight: backupInfoItem.height

            enabled: root.enabled && fileName.length > 0

            onFileNameChanged: {
                if (fileName) {
                    sailfishBackup.call("logFileForBackup", [fileName, model.accountId], function(path) {
                        logFilePath = path
                    })
                }
            }

            onClicked: {
                root.backupClicked(model.name, model.accountId, model.latestBackupInfo)
            }

            menu: logFilePath.length > 0 ? logMenuComponent : null

            Component {
                id: logMenuComponent

                ContextMenu {
                    MenuItem {
                        //: View the logged details for this backup
                        //% "View log"
                        text: qsTrId("vault-me-backup_log")

                        onClicked:{
                            pageStack.animatorPush(Qt.resolvedUrl("LogPage.qml"),
                                                   {"filePath": logFilePath})
                        }
                    }
                }
            }

            BackupInfoItem {
                id: backupInfoItem

                width: root.width
                sourceName: model.name
                backupInfo: model.latestBackupInfo
                highlighted: backupInfoDelegate.highlighted
                today: root.today
            }
        }
    }

    DBusInterface {
        id: sailfishBackup

        service: "org.sailfishos.backup"
        path: "/sailfishbackup"
        iface: "org.sailfishos.backup"
    }
}
