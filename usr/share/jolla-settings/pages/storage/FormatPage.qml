import QtQuick 2.1
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private
import Nemo.Configuration 1.0
import org.nemomobile.systemsettings 1.0

Page {
    id: root

    property QtObject partition
    property var model
    readonly property int partitionStatus: partition.status

    // Suppress changes caused by file system removal when formatting starts. File system removal will cleanup label of
    // the storage.
    property bool _busy
    readonly property bool _formatting: _busy || partitionStatus == PartitionModel.Formatting

    onPartitionStatusChanged: {
        if (partitionStatus == PartitionModel.Formatting) {
            _busy = false
        }
    }

    readonly property string _targetFilesystem: {
        if (encryptSwitch.checked)
            return "ext4"

        if (!filesystemWhitelist.hasExt4)
            return "vfat"

        var supportsVfat = false

        var supportedFormatTypes = model.supportedFormatTypes
        for (var i = 0; i < supportedFormatTypes.length; ++i) {
            if (supportedFormatTypes[i] === "vfat")
                supportsVfat = true
        }

        if (!partition.canMount) {
            if (partition.bytesTotal <= 32*1024*1024*1024 && supportsVfat)
                return "vfat"
            else
                return "ext4"
        } else {
            if (partition.bytesTotal <= 32*1024*1024*1024)
                return supportsVfat ? "vfat" : ""
            else
                return "ext4"
        }
    }


    SilicaFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height + Theme.paddingLarge

        Column {
            id: contentColumn
            width: parent.width

            spacing: Theme.paddingLarge

            visible: opacity > 0
            opacity: !_formatting ? 1 : 0
            Behavior on opacity { FadeAnimator { } }

            PageHeader {
                title: partition.drive.connectionBus === PartitionModel.USB ?
                           //% "Format USB storage"
                           qsTrId("settings_storage-he-format_usb_storage") :
                           //% "Format memory card"
                           qsTrId("settings_storage-he-format_memory_card")
            }

            StorageLabel {
                visible: !partition.canMount && !partition.isCryptoDevice
                height: implicitHeight + Theme.paddingLarge
                text: {
                    if (partition.drive.connectionBus === PartitionModel.USB) {
                        return partition.filesystemType !== ""
                                  //: %1 is the name of the incompatible file system, e.g. 'exFAT'. %2 is the name of the compatible file system, e.g. 'ext4'.
                                  //% "This USB storage uses an incompatible file system (using %1). To be able to use the card, formatting to a compatible file system (%2) is needed."
                                ? qsTrId("settings_storage-la-incompatible_usb_storage_filesystem").arg(partition.filesystemType).arg(root._targetFilesystem)
                                  //: %1 is the name of the compatible file system, e.g. 'ext4'.
                                  //% "This USB storage uses an unknown incompatible file system. To be able to use the card, formatting to a compatible file system (%1) is needed."
                                : qsTrId("settings_storage-la-unknown_incompatible_usb_storage_filesystem").arg(root._targetFilesystem)
                    } else {
                        return partition.filesystemType !== ""
                                  //: %1 is the name of the incompatible file system, e.g. 'exFAT'. %2 is the name of the compatible file system, e.g. 'ext4'.
                                  //% "This memory card uses an incompatible file system (using %1). To be able to use the card, formatting to a compatible file system (%2) is needed."
                                ? qsTrId("settings_storage-la-incompatible_memory_card_filesystem").arg(partition.filesystemType).arg(root._targetFilesystem)
                                  //: %1 is the name of the compatible file system, e.g. 'ext4'.
                                  //% "This memory card uses an unknown incompatible file system. To be able to use the card, formatting to a compatible file system (%1) is needed."
                                : qsTrId("settings_storage-la-unknown_incompatible_memory_card_filesystem").arg(root._targetFilesystem)
                    }
                }
            }

            StorageLabel {
                text: partition.drive.connectionBus === PartitionModel.USB
                        //% "Please make a backup of the USB storage contents before formatting. All data on the card will be destroyed."
                      ? qsTrId("settings_storage-la-usb_storage_backup_warning")
                        //% "Please make a backup of the memory card contents before formatting. All data on the card will be destroyed."
                      : qsTrId("settings_storage-la-memory_card_backup_warning")
            }

            TextField {
                id: storageName

                width: parent.width

                placeholderText: label

                label: partition.drive.connectionBus === PartitionModel.USB
                         //% "USB storage name"
                       ? qsTrId("settings_storage-ph-usb_storage_name")
                         //% "Memory card name"
                       : qsTrId("settings_storage-ph-memory_card_name")

                VerticalAutoScroll.bottomMargin: confirm.height + formatButton.height + Theme.paddingLarge

                EnterKey.iconSource: password.enabled ? "image://theme/icon-m-enter-next" : "image://theme/icon-m-enter-close"
                EnterKey.onClicked: {
                    if (password.enabled) {
                        password.focus = true
                    }
                }
            }

            ConfigurationValue {
                id: filesystemWhitelist

                readonly property bool hasExt4: {
                    if (value.length === 0) {
                        return true
                    }

                    for (var i = 0; i < value.length; ++i) {
                        if (value[i] === "ext4") {
                            return true
                        }
                    }

                    return false
                }

                key: "/org/freedesktop/udisks2/filesystem/whitelist"
                defaultValue: []
            }

            TextSwitch {
                id: encryptSwitch

                visible: filesystemWhitelist.hasExt4 && !partition.isCryptoDevice

                //% "Encrypt"
                text: qsTrId("settings_storage-la-encrypt_switch")
            }

            Column {
                visible: !partition.isCryptoDevice
                height: encryptSwitch.checked ? implicitHeight : 0
                opacity: encryptSwitch.checked ? 1.0 : 0.0
                width: parent.width

                Behavior on height {
                    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                }
                Behavior on opacity { FadeAnimator { } }

                StorageLabel {
                    height: implicitHeight + Theme.paddingLarge

                    text: partition.drive.connectionBus === PartitionModel.USB
                            //: Shown when "Encrypt" switch is enabled on the format page for USB storage.
                            //% "The encrypted USB storage is meant to be used with your device only. There may be compatibility issues with other systems."
                          ? qsTrId("settings_storage-la-encrypted_usb_storage_description")
                            //: Shown when "Encrypt" switch is enabled on the format page for memory card.
                            //% "The encrypted card is meant to be used with your device only. There may be compatibility issues with other systems."
                          : qsTrId("settings_storage-la-encrypted_memory_card_description")
                }

                PasswordField {
                    id: password

                    readonly property bool match: text == confirm.text

                    enabled: encryptSwitch.checked
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: confirm.focus = true
                }

                PasswordField {
                    id: confirm

                    //% "Confirm"
                    label: qsTrId("components-la-password_confirm")
                    placeholderText: label
                    enabled: encryptSwitch.checked
                    errorHighlight: !password.match

                    EnterKey.iconSource: "image://theme/icon-m-enter-close"
                }
            }

            Button {
                id: formatButton

                anchors.horizontalCenter: parent.horizontalCenter
                enabled: !encryptSwitch.checked || (password.length > 0 && password.match)

                //: File system used for formatting is shown in the brackets.
                //% "Format (%1)"
                text: qsTrId("settings_storage-la-format").arg(encryptSwitch.checked ? "luks" : root._targetFilesystem)
                onClicked: {
                    // Formatting non-encrypted works and handles unmounting before formatting file system.
                    // However, when formatting an encrypted device unmounting doesn't work. Hence, this notification.
                    // This notification can be removed if/when unmounting before encrypting starts working.
                    if (encryptSwitch.checked && partition.status === PartitionModel.Mounted) {
                        storageErrorNotification.previewBody = partition.drive.connectionBus === PartitionModel.USB
                                  //: Displayed when formatting encrypted device but device is already mounted.
                                  //% "Unmount USB storage before formatting an encrypted device."
                                ? qsTrId("settings_storage-la-usb_storage_formatting_encrypted_already_mounted")
                                  //: Displayed when formatting encrypted device but device is already mounted.
                                  //% "Unmount memory card before formatting an encrypted device."
                                : qsTrId("settings_storage-la-memory_card_formatting_encrypted_already_mounted")
                        storageErrorNotification.notify()
                    } else {
                        _busy = true
                        var devicePath = partition.cryptoBackingDevicePath ? partition.cryptoBackingDevicePath : partition.devicePath
                        model.format(devicePath, {
                                         "filesystemType": root._targetFilesystem,
                                         "label": storageName.text,
                                         "encrypt-passphrase": (encryptSwitch.checked ? password.text : "")
                                     })
                    }
                    pageStack.pop()
                }
            }
        }
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        spacing: Theme.paddingLarge

        opacity: _formatting ? 1 : 0
        Behavior on opacity { FadeAnimator { } }

        BusyIndicator {
            anchors.horizontalCenter: parent.horizontalCenter
            size: BusyIndicatorSize.Large
            running: _formatting
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeLarge

            //% "Formatting..."
            text: qsTrId("settings_storage-la-formatting_ongoing")
        }
    }

    StorageNotification {
        id: storageErrorNotification
    }

    Connections {
        target: model
        onFormatError: {
            console.log("Formatting error occured:", error)
            _busy = false
        }
    }
}
