/****************************************************************************
**
** Copyright (c) 2015 - 2020 Jolla Ltd.
** Copyright (c) 2020 Open Mobile Platform LLC.
** License: Proprietary
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.systemsettings 1.0
import Qt.labs.folderlistmodel 2.1

Page {
    id: storagePage

    property Item contextMenu

    function refresh() {
        internalUserPartitions.refresh()
        internalSystemPartitions.refresh()
        externalPartitions.refresh()
    }

    onStatusChanged: {
        if (status == PageStatus.Activating) {
            // Refresh the storage counts.
            refresh()
        }
    }

    PartitionModel {
        id: internalUserPartitions

        storageTypes: PartitionModel.User | PartitionModel.Mass
    }

    PartitionModel {
        id: internalSystemPartitions

        storageTypes: PartitionModel.System
    }

    PartitionModel {
        id: externalPartitions

        storageTypes: PartitionModel.External | PartitionModel.ExcludeParents

        onLockError: {
            //% "Memory card locking failed"
            storageErrorNotification.body = qsTrId("settings_storage-la-memory_card_locking_failed")
            storageErrorNotification.notify()
        }

        onMountError: {
            //% "Memory card mounting failed"
            storageErrorNotification.body = qsTrId("settings_storage-la-memory_card_mounting_failed")
            storageErrorNotification.notify()
        }

        onFormatError: {
            if (error == PartitionModel.ErrorNotAuthorizedDismissed ||
                       error == PartitionModel.ErrorNotAuthorizedCanObtain ||
                       error == PartitionModel.ErrorNotAuthorized) {
                //: Displayed when user did not authorize memory card format operation.
                //% "Memory card formatting not authorized"
                storageErrorNotification.body = qsTrId("settings_storage-la-memory_card_format_not_authorized")
            } else {
                storageErrorNotification.isTransient = false

                //: Summary text of memory card formatting failed
                //% "Memory card formatting failed"
                storageErrorNotification.summary = qsTrId("settings_storage-la-memory_card_format_failed_summary")

                //: Body text of memory card formatting failed
                //% "The memory card might be in unstable state."
                storageErrorNotification.body = qsTrId("settings_storage-la-memory_card_format_failed_body")
            }
            storageErrorNotification.notify()
        }

        onUnmountError: {
            if (error == PartitionModel.ErrorDeviceBusy) {
                //: Displayed when unmounting an external storage (sd card, USB otg mass storage, etc) that is busy
                //% "External storage busy, cannot unmount"
                storageErrorNotification.body = qsTrId("settings_storage-la-memory_card_busy")
            } else if (error == PartitionModel.ErrorNotMounted) {
                // This should be a bit theoretical error as unmounting should not be possible from the ui
                // if the device is nout mounted but let's keep it here regardless.
                //: Displayed when trying to unmount a device that is not mounted
                //% "Device already unmounted"
                storageErrorNotification.body = qsTrId("settings_storage-la-memory_card_already_unmounted")
            } else {
                //% "Memory card unmount failed"
                storageErrorNotification.body = qsTrId("settings_storage-la-memory_card_unmount_failed")
            }
            storageErrorNotification.notify()
        }
    }

    StorageNotification {
        id: storageErrorNotification
    }

    SilicaListView {
        id: flickable

        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                //% "Update"
                text: qsTrId("settings_storage-me-update")
                onClicked: storagePage.refresh()
            }
        }

        header: Column {
            width: parent.width

            PageHeader {
                //% "Storage"
                title: qsTrId("settings_storage-he-storage")
            }

            Item { width: 1; height: Theme.paddingLarge }

            Repeater {
                model: internalUserPartitions

                delegate: DiskUsageItem {
                    width: parent.width
                }
            }

            Repeater {
                model: internalSystemPartitions

                delegate: DiskUsageItem {
                    width: parent.width
                }
            }
        }

        model: externalPartitions

        delegate: DiskUsageItem {
            id: cardItem

            property Item menuItem

            width: flickable.width
            menu: contextMenuComponent
            openMenuOnPressAndHold: false
            removable: true
            onClicked: {
                if (errorState) {
                    showFormatDialog()
                } else if (model.status == PartitionModel.Mounted) {
                    var obj = pageStack.animatorPush("DirectoryPage.qml", {
                                                         parentPage: storagePage,
                                                         partition: model,
                                                         title: Qt.binding(function() {
                                                             if (model.drive.connectionBus === PartitionModel.USB) {
                                                                 //: USB storage with storage name
                                                                 //% "USB storage · %1"
                                                                 return qsTrId("settings_storage-he-usb_storage_title_with_label").arg(model.deviceLabel)
                                                             }

                                                             //: Memory card with memory card name
                                                             //% "Memory card · %1"
                                                             return qsTrId("settings_storage-he-memory_card_title_with_label").arg(model.deviceLabel)
                                                         })
                                                     })
                    obj.pageCompleted.connect(function(page) {
                        page.formatClicked.connect(function() {
                            showFormatDialog()
                        })
                    })
                } else if (!cardItem.busy) {
                    openContextMenu()
                }
            }

            onPressAndHold: openContextMenu()

            function showFormatDialog() {
                pageStack.animatorPush("FormatPage.qml",
                                       {
                                           partition: model,
                                           model: externalPartitions,
                                           cryptoDevice: model.isCryptoDevice
                                       })
            }

            function openContextMenu() {
                menuItem = openMenu({
                                        memoryCardItem: cardItem,
                                        supported: model.canMount,
                                        partition: model,
                                    })
            }

            function mount() {
                externalPartitions.mount(model.devicePath)
            }

            function unmount() {
                externalPartitions.unmount(model.devicePath)
            }

            function unlock() {
                var objPath = externalPartitions.objectPath(model.devicePath)
                encryptionUnlocker.unlock(cardItem, objPath)
            }

            function lock() {
                externalPartitions.lock(model.cryptoBackingDevicePath)
            }

            ListView.delayRemove: removeAnimation.running
            ListView.onRemove: SequentialAnimation {
                id: removeAnimation
                running: false
                FadeAnimation { target: cardItem; to: 0; duration: 200 }
                NumberAnimation { target: cardItem; properties: "height"; to: 0; duration: 200; easing.type: Easing.InOutQuad }
            }

            ListView.onAdd: SequentialAnimation {
                running: false
                PropertyAction { target: cardItem; properties: "opacity"; value: 0 }
                NumberAnimation {
                    target: cardItem
                    properties: "height"
                    from: 0
                    to: cardItem.contentHeight
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
                FadeAnimation { target: cardItem; to: 1; duration: 200 }
                ScriptAction { script: {
                        cardItem.height = Qt.binding(function() {
                            return cardItem.menuOpen ? (cardItem.menuItem ? cardItem.menuItem.height : 0) + cardItem.contentHeight : cardItem.contentHeight
                        })
                    }
                }
            }
        }

        footer: Column {
            DiskUsageItem {
                id: noCardItem

                property bool show: externalPartitions.count === 0
                onShowChanged: {
                    visible = true
                    if (show) {
                        fadeOut.stop()
                        fadeIn.start()
                    } else {
                        fadeIn.stop()
                        fadeOut.start()
                    }
                }

                Component.onCompleted: {
                    if (externalPartitions.count > 0) {
                        height = 0
                        opacity = 0
                    }
                }

                // FIXME: This should only be display if an SD slot is available on the device.
                width: flickable.width
                enabled: false

                SequentialAnimation {
                    id: fadeIn
                    NumberAnimation {
                        target: noCardItem
                        properties: "height"
                        to: noCardItem.implicitHeight
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }
                    FadeAnimation {
                        target: noCardItem
                        to: 1
                    }
                }

                SequentialAnimation {
                    id: fadeOut
                    FadeAnimation {
                        target: noCardItem
                        to: 0
                    }
                    NumberAnimation {
                        target: noCardItem
                        properties: "height"
                        to: 0
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }
                }

                property var model: {
                    "storageType": PartitionModel.External,
                    "mounted": false,
                    "mountPath": "",
                    "bytesAvailable": 0,
                    "bytesTotal": 0,
                    "filesystemType": "",
                    "devicePath": "",
                    "isEncrypted": false,
                    "isSupportedFileSystemType": true,
                    "status": PartitionModel.Unmounted,
                    "deviceLabel": ""
                }
            }
            Item {
                width: flickable.width
                height: Theme.paddingLarge
            }
        }

        VerticalScrollDecorator {}
    }

    EncryptionUnlocker {
        id: encryptionUnlocker
    }

    Component {
        id: contextMenuComponent

        ContextMenu {
            property Item memoryCardItem
            property QtObject partition
            readonly property bool mounted: partition.status === PartitionModel.Mounted
            property bool supported

            MenuItem {
                visible: supported && (mounted || partition.status === PartitionModel.Unmounted)
                text: mounted ?
                          //% "Unmount"
                          qsTrId("settings_storage-me-unmount_card") :
                          //% "Mount"
                          qsTrId("settings_storage-me-mount_card")
                onDelayedClick: {
                    if (mounted)
                        memoryCardItem.unmount()
                    else
                        memoryCardItem.mount()
                }
            }

            MenuItem {
                // Device needs to be locked first to be able to format.
                visible: !mounted && !partition.cryptoBackingDevicePath

                //% "Format"
                text: qsTrId("settings_storage-me-format_memory_card")
                onClicked: memoryCardItem.showFormatDialog()
            }

            MenuItem {
                visible: partition.status === PartitionModel.Locked || partition.cryptoBackingDevicePath

                text: partition.cryptoBackingDevicePath ?
                          //% "Lock"
                          qsTrId("settings_storage-me-lock_memory_card") :
                          //% "Unlock"
                          qsTrId("settings_storage-me-unlock_memory_card")
                onClicked: {
                    if (partition.cryptoBackingDevicePath)
                        memoryCardItem.lock()
                    else
                        memoryCardItem.unlock()
                }
            }
        }
    }
}
