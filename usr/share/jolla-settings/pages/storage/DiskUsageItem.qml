import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0

ListItem {
    id: diskUsageArea

    property bool removable
    readonly property bool formatting: model.status == PartitionModel.Formatting || formattingInfo.running
    readonly property alias busy: circle.busy
    readonly property bool errorState: !model.isSupportedFileSystemType && !model.isEncrypted && !diskUsageArea.busy
    property int partitionStatus: model.status
    readonly property real _maxWidth: diskUsageArea.width - Theme.horizontalPageMargin * 2

    // When formatting a crypto container we're hitting formatting state twice.
    // Hence, do not restart
    onPartitionStatusChanged: {
        if (model.status == PartitionModel.Formatting) formattingInfo.start()
    }

    onClicked: {
        if (model.status == PartitionModel.Mounted && !removable) {
            pageStack.animatorPush('DiskUsagePage.qml', { parentPage: pageStack.currentPage, partition: model, title: getTitle() })
        }
    }

    function getTitle() {
        switch (model.storageType) {
        case PartitionModel.System:
            //% "System data"
            return qsTrId("settings_about-la-system_data")
        case PartitionModel.User:
            //% "User data"
            return qsTrId("settings_about-la-user_data")
        case PartitionModel.Mass:
            //% "Mass memory"
            return qsTrId("settings_about-la-mass_memory")
        case PartitionModel.External:
            switch (model.status) {
            case PartitionModel.Mounted:
                if (model.isCryptoDevice) {
                    if (model.drive.connectionBus === PartitionModel.USB) {
                        //% "Encrypted USB storage"
                        return qsTrId("settings_storage-la-encrypted_usb_storage")
                    }

                    //: Encrypted memory card
                    //% "Encrypted memory card"
                    return qsTrId("settings_storage-la-encrypted_memory_card")
                } else if (model.drive.connectionBus === PartitionModel.USB) {
                    //: USB storage with filesystem type
                    //% "USB storage (%1)"
                    return qsTrId("settings_storage-la-usb_storage").arg(model.filesystemType)
                } else {
                    //: Memory card with filesystem type
                    //% "Memory card (%1)"
                    return qsTrId("settings_storage-la-memory_card").arg(model.filesystemType)
                }
            case PartitionModel.Mounting:
                //% "Mounting"
                return qsTrId("settings_storage-la-mounting")
            case PartitionModel.Unmounting:
                //% "Unmounting"
                return qsTrId("settings_storage-la-unmounting")
            case PartitionModel.Locked:
                if (model.drive.connectionBus === PartitionModel.USB) {
                    //% "Locked encrypted USB storage"
                    return qsTrId("settings_storage-la-locked_encrypted_usb_storage")
                }

                //% "Locked encrypted memory card"
                return qsTrId("settings_storage-la-memory_card_locked")
            case PartitionModel.Locking:
                //% "Locking"
                return qsTrId("settings_storage-la-locking")
            case PartitionModel.Unlocking:
                //% "Unlocking"
                return qsTrId("settings_storage-la-unlocking")
            default:
                if (formatting) {
                    return formattingInfo.running ?
                                //% "Formatting takes time"
                                qsTrId("settings_storage-la-formatting_takes_time") :
                                //% "Formatting"
                                qsTrId("settings_storage-la-formatting")
                }

                if (model.devicePath == "") {
                    //% "Memory card not inserted"
                    return qsTrId("settings_storage-la-memory_card_not_inserted")
                }

                if (model.canMount) {
                    if (model.isCryptoDevice) {
                        if (model.drive.connectionBus === PartitionModel.USB) {
                            //% "Unmounted encrypted USB storage"
                            return qsTrId("settings_storage-la-unmounted_encrypted_usb_storage")
                        }

                        //: Unmounted encrypted memory card
                        //% "Unmounted encrypted memory card"
                        return qsTrId("settings_storage-la-unmounted_encrypted_memory_card")
                    } else {
                        if (model.drive.connectionBus === PartitionModel.USB) {
                            //% "Unmounted USB storage (%1)"
                            return qsTrId("settings_storage-la-unmounted_usb_storage").arg(model.filesystemType)
                        }

                        //% "Unmounted memory card (%1)"
                        return qsTrId("settings_storage-la-unmounted_memory_card").arg(model.filesystemType)
                    }
                }


                if (model.drive.connectionBus === PartitionModel.USB) {
                    //% "Unsupported %1 USB storage"
                    return qsTrId("settings_storage-la-unsupported_usb_storage").arg(model.drive.vendor)
                }

                //% "Unsupported %1 memory card"
                return qsTrId("settings_storage-la-unsupported_memory_card").arg(model.drive.vendor)

            }
        default:
            // Unknown storage type -- show the raw path and raw storage type instead
            return model.mountPath
        }
    }

    enabled: !circle.busy

    width: parent.width
    contentHeight: statusLabel.y + statusLabel.height + Theme.paddingMedium

    Timer {
        id: formattingInfo
        interval: 3000
    }

    Column {
        id: column
        
        y: Theme.paddingMedium
        width: Theme.itemSizeHuge
        spacing: Theme.paddingMedium
        anchors.horizontalCenter: parent.horizontalCenter

        DiskUsageCircle {
            id: circle

            readonly property bool busy: model.status == PartitionModel.Mounting ||
                                         model.status == PartitionModel.Unmounting ||
                                         model.status == PartitionModel.Unlocking ||
                                         model.status == PartitionModel.Locking ||
                                         formatting

            property real animationValue: usedSpace() / model.bytesTotal
            function usedSpace() { return  model.bytesTotal - model.bytesAvailable }

            onBusyChanged: {
                if (busy) {
                    usageBehavior.enabled = false
                    animationValue = value
                    usageBehavior.enabled = true
                    // 24h hours
                    animationValue = 30.0 * 60.0 * 24.0
                } else {
                    var base = Math.floor(animationValue)

                    if (alternateColors) {
                        // Do no stop the animation when alternateColors is true.
                        base += 1
                    } else if (value > (usedSpace() / model.bytesTotal)) {
                        // Finish the current loop and do another so as to not settle on alternateColors
                        base += 2
                    }

                    animationValue = Qt.binding(function() {
                        if (model.bytesTotal === 0)
                            return base

                        return base + usedSpace() / model.bytesTotal
                    })
                }
            }

            value: animationValue % 1
            highlighted: diskUsageArea.highlighted || model.status != PartitionModel.Mounted
            alternateColors: (Math.floor(animationValue) % 2) == 1

            Behavior on animationValue {
                id: usageBehavior
                SmoothedAnimation {
                    duration: -1
                    velocity: 0.5   // 0 -> 1 in two seconds.
                    maximumEasingTime: 60
                }
            }

            DiskUsageLabelGroup {
                id: labelGroup

                enabled: model.status === PartitionModel.Mounted
                width: parent.width * 0.7
                anchors.centerIn: parent

                highlighted: diskUsageArea.highlighted
                topLabelText: enabled ? Format.formatFileSize(circle.usedSpace()) : ""
                //% "Used"
                bottomLabelText: enabled ? qsTrId("settings_storage-la-used") : ""
            }
        }
        
        Column {
            width: parent.width
            Label {
                text: getTitle()
                anchors.horizontalCenter: parent.horizontalCenter
                width: contentWidth > _maxWidth ? _maxWidth : implicitWidth
                horizontalAlignment: contentWidth > _maxWidth ? Text.AlignLeft : Text.AlignHCenter
                truncationMode: TruncationMode.Fade
                font.pixelSize: Theme.fontSizeSmall
                color: circle.primaryColor
            }
            Label {
                visible: diskUsageArea.removable && model.filesystemType !== "" && model.status != PartitionModel.Formatting
                width: contentWidth > _maxWidth ? _maxWidth : implicitWidth
                horizontalAlignment: contentWidth > _maxWidth ? Text.AlignLeft : Text.AlignHCenter
                truncationMode: TruncationMode.Fade
                anchors.horizontalCenter: parent.horizontalCenter
                color: model.isSupportedFileSystemType || model.isEncrypted ? circle.primaryColor : "#ff4d4d"
                font.pixelSize: Theme.fontSizeSmall
                text: model.deviceLabel
            }
        }
    }

    MemoryCardStatus {
        id: statusLabel
        anchors.top: column.bottom
        visible: errorState
        highlighted: diskUsageArea.highlighted
    }

    DiskUsageLabelGroup {
        y: column.y + circle.height/2 - height/2
        anchors {
            left: column.right
            leftMargin: Theme.paddingMedium
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
        }

        enabled: labelGroup.enabled
        highlighted: diskUsageArea.highlighted
        ruler.width: width*0.7
        horizontalAlignment: Text.AlignRight
        topLabelText: enabled && model.devicePath !== "" ? Format.formatFileSize(model.bytesAvailable) : ""
        bottomLabelText: {
            if (!enabled) {
                return ""
            } else if (model.storageType == PartitionModel.User || model.storageType == PartitionModel.Mass) {
                //% "Available"
                return qsTrId("settings_storage-la-available")
            } else {
                //% "Free"
                return qsTrId("settings_storage-la-free")
            }
        }
    }
}
