/*
 * Copyright (c) 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0
import Sailfish.Encryption 1.0
import org.nemomobile.devicelock 1.0
import org.nemomobile.systemsettings 1.0

Page {
    id: page

    // Device lock autentication

    // threshold above which we may reset without charger
    readonly property int batteryThreshold: 15
    readonly property bool batteryChargeOk: battery.chargePercentage > batteryThreshold
    // To be checked
    readonly property bool applicationActive: Qt.application.active
    // external storage data
    property string selectedDevPath: "tmp"
    property bool selectedDevSuitable: false
    property bool hasHomeCopy: copyHelper.hasHomeCopyService()

    property EncryptionService encryptionService
    property CopyService copyService

    function createBackupLink() {
        //: A link to Settings | System | Backup
        //: Action or verb that can be used for %1 in settings_encryption-la-encrypt_user_data_warning and
        //: settings_encryption-la-encrypt_user_data_description
        //: Strongly proposing user to do a backup.
        //% "Back up"
        var backup = qsTrId("settings_encryption-la-back_up")
        return "<a href='backup'>" + backup + "</a>"
    }

    function devPath() {
        return sdSwitch.checked ? selectedDevPath : "tmp"
    }

    BatteryStatus {
        id: battery
    }

    USBSettings {
        id: usbSettings
    }

    CopyHelper {
        id: copyHelper
    }

    EncryptionSettings {
        id: encryptionSettings
        onEncryptingHome: lipstick.startEncryptionPreparation()
        onEncryptHomeError: console.warn("Home encryption failed. Maybe token expired.")
    }

    Component {
        id: encryptionServiceComponent
        EncryptionService {}
    }

    Component {
        id: copyServiceComponent
        CopyService {}
    }

    DBusInterface {
        id: dsmeDbus
        bus: DBus.SystemBus
        service: "com.nokia.dsme"
        path: "/com/nokia/dsme/request"
        iface: "com.nokia.dsme.request"
    }

    DBusInterface {
        id: lipstick
        bus: DBus.SystemBus
        service: "org.nemomobile.lipstick"
        path: "/shutdown"
        iface: "org.nemomobile.lipstick"

        function startEncryptionPreparation() {
            lipstick.call("setShutdownMode", ["reboot"],
                          function(success) {
                              prepareEncryption.running = true
                          },
                          function(error, message) {
                              console.info("Error occured when entering to reboot mode:", error, "message:", message)
                          }
                          )
        }
    }

    Timer {
        id: prepareEncryption

        property string securityCode

        interval: 3000
        onTriggered: {
            page.encryptionService = encryptionServiceComponent.createObject(root)
            page.encryptionService.prepare(securityCode, "zero")
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        VerticalScrollDecorator {}

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: encryptionSettings.homeEncrypted
                       ? //% "Encryption information"
                         qsTrId("settings_encryption-he-encryption_information")
                       :  //% "Encryption"
                         qsTrId("settings_encryption-he-encryption")
            }

            Item {
                id: batteryWarning

                width: parent.width - 2*Theme.horizontalPageMargin
                height: Math.max(batteryIcon.height, batteryText.height)
                x: Theme.horizontalPageMargin
                visible: !page.batteryChargeOk && !encryptionSettings.homeEncrypted

                Image {
                    id: batteryIcon
                    anchors.verticalCenter: parent.verticalCenter
                    source: "image://theme/icon-l-battery"
                }

                Label {
                    id: batteryText

                    anchors {
                        left: batteryIcon.right
                        leftMargin: Theme.paddingMedium
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.highlightColor
                    wrapMode: Text.Wrap
                    text: battery.chargerStatus === BatteryStatus.Connected
                          ? //: Battery low warning for device reset when charger is attached. Same as settings_reset-la-battery_charging
                            //% "Battery level low. Do not remove the charger."
                            qsTrId("settings_encryption-la-battery_charging")
                          : //: Battery low warning for device reset when charger is not attached. Same as settings_reset-la-battery_level_low
                            //% "Battery level too low."
                            qsTrId("settings_encryption-la-battery_level_low")
                }
            }

            Item {
                id: mtpWarning

                width: parent.width - 2*Theme.horizontalPageMargin
                height: Math.max(mtpIcon.height, mtpText.height)
                x: Theme.horizontalPageMargin
                visible: usbSettings.currentMode == usbSettings.MODE_MTP && !encryptionSettings.homeEncrypted

                Image {
                    id: mtpIcon
                    anchors.verticalCenter: parent.verticalCenter
                    source: "image://theme/icon-m-usb"
                }

                Label {
                    id: mtpText

                    anchors {
                        left: mtpIcon.right
                        leftMargin: Theme.paddingMedium
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.highlightColor
                    wrapMode: Text.Wrap
                    text: //: USB MTP mode disconnect warning
                          //% "Media transfer (MTP) will be disconnected."
                          qsTrId("settings_encryption-la-mtp_disconnect")
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.highlightColor
                linkColor: Theme.primaryColor
                textFormat: Text.AutoText
                visible: !encryptionSettings.homeEncrypted

                //: Takes "Back up" (settings_encryption-la-back_up) formatted hyperlink as parameter.
                //: This is done because we're creating programmatically a hyperlink for it.
                //% "This will erase all user data from the device. "
                //% "This means losing user data that you have added to the device, reverts apps to clean state, accounts, contacts, photos and other media.<br><br>"
                //% "%1 user data to memory card before encrypting the device."
                text: qsTrId("settings_encryption-la-encrypt_user_data_description").arg(createBackupLink())

                onLinkActivated: pageStack.animatorPush("Sailfish.Vault.MainPage")
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                preferredWidth: Theme.buttonWidthMedium
                visible: !encryptionSettings.homeEncrypted

                //% "Encrypt"
                text: qsTrId("settings_encryption-bt-encrypt")
                onClicked: {
                    var obj = pageStack.animatorPush(Qt.resolvedUrl("HomeEncryptionDisclaimer.qml"), {
                                                         "encryptionSettings": encryptionSettings
                                                     })
                    var mandatoryDeviceLock
                    obj.pageCompleted.connect(function(p) {
                        p.accepted.connect(function() {
                            mandatoryDeviceLock = p.acceptDestinationInstance
                            p.acceptDestinationInstance.authenticated.connect(function(authenticationToken) {
                                prepareEncryption.securityCode = mandatoryDeviceLock.securityCode
                                if (hasHomeCopy)
                                    page.copyService = copyServiceComponent.createObject(root)
                                if (sdSwitch.checked) {
                                    var copyPage = pageStack.animatorPush(Qt.resolvedUrl("SDCopyPage.qml"))
                                    page.copyService.copyHome(selectedDevPath)
                                    page.copyService.copied.connect(function(success) {
                                        if (success) {
                                            encryptionSettings.encryptHome(authenticationToken)
                                        } else {
                                            pageStack.pop(page)
                                            completeAnimation()
                                            pageStack.animatorPush(Qt.resolvedUrl("SDCopyFailed.qml"))
                                            page.copyService.setCopyDev("")
                                        }
                                    })
                                } else {
                                    if (hasHomeCopy)
                                        page.copyService.setCopyDev("")
                                    encryptionSettings.encryptHome(authenticationToken)
                                }
                            })
                            p.acceptDestinationInstance.canceled.connect(function() {
                                pageStack.pop(page)
                            })
                        })
                        p.canceled.connect(function() {
                            pageStack.pop(page)
                        })
                    })
                }
                enabled: (page.batteryChargeOk || battery.chargerStatus === BatteryStatus.Connected)
                         && !encryptionSettings.homeEncrypted
                         && (!sdSwitch.checked || selectedDevSuitable)
            }
            TextSwitch {
                id: sdSwitch
                //% "Copy user data to memory card"
                text: qsTrId("settings_encryption-la-use_card")
                //% "An encrypted memory card can be used to keep user data."
                description: qsTrId("settings_encryption-la-use_card_description")
                visible: !encryptionSettings.homeEncrypted && hasHomeCopy && copyHelper.memorycard
            }

            ComboBox {
                id: sdComboBox
                enabled: sdSwitch.checked
                visible: !encryptionSettings.homeEncrypted && hasHomeCopy && copyHelper.memorycard
                //% "Encrypt using:"
                label: qsTrId("settings_encryption-la-encrypt_using")

                menu: ContextMenu {
                    id: sdMenu
                    property bool firstUpdate: true

                    Repeater {
                        id: sdRepeater
                        model: PartitionModel {
                            id: partitionModel
                            storageTypes: PartitionModel.External | PartitionModel.ExcludeParents
                        }

                        MenuItem {
                            //% "Memory card: (%1)"
                            text:  qsTrId("settings_encryption-memory_card").arg(Format.formatFileSize(bytesTotal))
                            onClicked: {
                                update()
                            }

                            Component.onCompleted: {
                                if (sdMenu.firstUpdate) {
                                    sdMenu.firstUpdate = false
                                    update()
                                }
                            }
                            function update() {
                                page.selectedDevSuitable = ((copyHelper.homeBytes() < bytesFree) && (mountPath !== "")
                                                           && copyHelper.checkWritable(mountPath))

                                sdComboBox.description = descriptionString((copyHelper.homeBytes() < bytesFree), (mountPath !== ""),
                                                                           copyHelper.checkWritable(mountPath), isCryptoDevice)
                                page.selectedDevPath = devicePath
                            }

                            function descriptionString(homeFits, mounted, writable, encrypted) {
                                if (!mounted) { //% "Card must be mounted"
                                    return qsTrId("settings_encryption-la-card_not_mounted")
                                } else if (!homeFits) { //% "User data doesn't fit SD card"
                                    return qsTrId("settings_encryption-la-data_doesnt_fit_to_card")
                                } else if (!writable) { //% "Selected card unwritable"
                                    return qsTrId("settings_encryption-la-card_unwritable")
                                } else if (!encrypted) { //% "Card must be encrypted"
                                    return qsTrId("settings_encryption-la-card_not_encrypted")
                                } else {
                                    return ""
                                }
                            }
                        }
                    }
                }
                descriptionColor: Theme.errorColor
                description: ""
            }

            Column {
                id: homeInfoColumn
                width: parent.width
                visible: encryptionSettings.homeEncrypted

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.highlightColor

                    //: Shown in the Settings -> Encryption page when user data is already encrypted.
                    //% "Your user data is encrypted which means that only authorized users can access it. Users are authenticated with security code."
                    text: qsTrId("settings_encryption-la-encryption_user_data_description")
                }

                SectionHeader {
                    //% "User data"
                    text: qsTrId("settings_encryption-la-encryption_user_data")
                }

                DetailItem {
                    //% "Encryption"
                    label: qsTrId("settings_encryption-la-encryption")
                    //% "Enabled"
                    value: qsTrId("settings_encryption-la-enabled")
                }

                DetailItem {
                    visible: homeInfo.type
                    //% "Device type"
                    label: qsTrId("settings_encryption-la-device_type")
                    value: homeInfo.type
                }

                DetailItem {
                    visible: homeInfo.version
                    //% "Version"
                    label: qsTrId("settings_encryption-la-version")
                    value: homeInfo.version
                }

                DetailItem {
                    visible: homeInfo.size > 0
                    //% "Size"
                    label: qsTrId("settings_encryption-la-size")
                    value: Format.formatFileSize(homeInfo.size)
                }
            }

            Loader {
                id: homeInfo

                readonly property string type: item && item.type || ""
                readonly property string version: item && item.version || ""
                readonly property double size: item && item.size || 0

                active: encryptionSettings.homeEncrypted
                sourceComponent: Component {
                    HomeInfo {}
                }
            }
        }
    }
}
