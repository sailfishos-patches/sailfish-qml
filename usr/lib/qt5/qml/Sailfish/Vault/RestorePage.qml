/****************************************************************************************
**
** Copyright (c) 2020 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private
import Sailfish.Vault 1.0

Page {
    id: root

    property var storageListModel

    property int cloudAccountId
    property alias sourceName: backupInfoItem.sourceName
    property alias backupInfo: backupInfoItem.backupInfo

    backNavigation: !gestureOverride.active

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height

        VerticalScrollDecorator {}

        Column {
            id: contentColumn
            width: parent.width

            PageHeader {
                //% "Restore device"
                title: qsTrId("vault-he-restore_device")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin*2
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.highlightColor

                //: Label above the name of the backup that will be restored to the device.
                //% "The device will be restored using"
                text: qsTrId("vault-la-the_device_will_be_restored_using")
            }

            BackupInfoItem {
                id: backupInfoItem

                enabled: false
                today: new Date()
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin*2
                height: implicitHeight + Theme.paddingLarge * 2
                wrapMode: Text.Wrap
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.highlightColor

                text: cloudAccountId > 0
                      //: Describes the data restoration process from a cloud service
                      //% "Your data will now be downloaded and restored. Depending on the amount of content you have, it might take some time. Please wait without turning off your device or disconnecting from your internet service."
                    ? qsTrId("vault-la-restore_cloud_description")
                      //: Describes the data restoration process from a memory card
                      //% "Your data will now be copied from the memory card and restored. Depending on the amount of content you have, it might take some time. Please wait without turning off your device or removing the memory card."
                    : qsTrId("vault-la-restore_memory_card_description")
            }

            BackupRestoreProgressItem {
                id: backupRestoreProgressItem

                storageListModel: root.storageListModel
                operationType: "restore"

                //: Start process of restoring data from backup
                //% "Restore"
                actionButtonText: qsTrId("vault-bt-restore")

                onActionButtonClicked: {
                    if (root.cloudAccountId > 0) {
                        restoreFromCloud(root.cloudAccountId, backupInfoItem.filePath)
                    } else {
                        restoreFromFile(backupInfoItem.filePath)
                    }
                }

                onOkButtonClicked: {
                    pageStack.pop()
                }
            }
        }
    }

    Private.WindowGestureOverride {
        id: gestureOverride
        active: backupRestoreProgressItem.busy
    }
}
