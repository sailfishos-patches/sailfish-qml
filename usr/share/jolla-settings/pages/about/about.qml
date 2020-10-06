/*
 * Copyright (c) 2013 - 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.systemsettings 1.0
import org.nemomobile.devicelock 1.0
import org.nemomobile.ofono 1.0
import org.nemomobile.dbus 2.0

Page {
    id: aboutPage

    AboutSettings {
        id: aboutSettings
    }

    DeviceInfo {
        id: deviceInfo
    }

    DBusInterface {
        id: csd
        bus: DBus.SessionBus
        service: "com.jolla.csd"
        path: "/com/jolla/csd"
        iface: "com.jolla.csd"
    }

    EncryptionSettings {
        id: encryptionSettings
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        Column {
            id: content

            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                //% "About device"
                title: qsTrId("settings_about-he-about_device")
            }

            Column {
                width: parent.width

                Text {
                    width: parent.width
                    height: implicitHeight + Theme.paddingSmall // match DetailItem padding
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeSmall
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap

                    text: {
                        var operatingSystem = aboutSettings.localizedOperatingSystemName
                        var version = aboutSettings.softwareVersionId
                        // Maximum major.minor version digits
                        return operatingSystem + " " + version.substring(0, version.indexOf(".", version.indexOf(".") + 1))
                    }
                }

                DetailItem {
                    //% "Manufacturer"
                    label: qsTrId("settings_about-la-manufacturer")
                    value: deviceInfo.manufacturer
                }

                DetailItem {
                    //% "Product name"
                    label: qsTrId("settings_about-la-product_name")
                    value: deviceInfo.prettyName
                }

                MouseArea {
                    property bool open
                    onClicked: open = !open
                    onPressAndHold: open = !open
                    width: parent.width
                    height: imeiItem.active ? (imeiItem.height + (open ? imeiSvItem.height : 0)) : 0
                    Behavior on height { enabled: modemManager.ready; NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                    clip: true

                    Column {
                        width: parent.width

                        DetailItem {
                            id: imeiItem

                            property bool active: deviceInfo.hasFeature(DeviceInfo.FeatureCellularVoice) ||
                                                  deviceInfo.hasFeature(DeviceInfo.FeatureCellularData)

                            //% "IMEI"
                            label: qsTrId("settings_about-la-imei")
                            value: modemManager.imeiCodes.join(Format.listSeparator)
                            visible: active
                        }

                        DetailItem {
                            id: imeiSvItem
                            //% "IMEI SV"
                            label: qsTrId("settings_about-la-imei_sv")
                            value: modemManager.imeisvCodes.join(Format.listSeparator)
                            visible: value != ""
                        }
                    }

                    OfonoModemManager {
                        id: modemManager
                    }
                }

                DetailItem {
                    //% "Serial number"
                    label: qsTrId("settings_about-la-serial")
                    value: aboutSettings.serial
                    visible: aboutSettings.serial !== ''
                }

                MouseArea {
                    property int numberOfTaps

                    // CSD tool invoker
                    onClicked: {
                        numberOfTaps++
                        if (numberOfTaps === 5) {
                            numberOfTaps = 0
                            csd.call("show", [])
                        }
                        expander.open = false
                    }
                    onPressAndHold: if (!expander.open) expander.open = true

                    clip: true
                    width: parent.width
                    height: buildItem.height + (expander.open ? expander.height : 0)
                    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

                    DetailItem {
                        id: buildItem
                        //: The build/version number of the currently installed Sailfish OS.
                        //% "Build"
                        label: qsTrId("settings_about-la-sailfish_os_build")

                        //% "Unknown version"
                        value: aboutSettings.localizedSoftwareVersion ||
                               qsTrId("settings_about-la-unknown_sailfish_version")
                    }
                    Column {
                        id: expander
                        property bool open
                        y: buildItem.height
                        width: parent.width
                        Loader {
                            width: parent.width
                            active: expander.open
                            source: "AdditionalSoftwareField.qml"
                        }
                        DetailItem {
                            //: Label for the version of the vendor-specific software package
                            //% "Vendor software"
                            label: qsTrId("settings_about-la-vendor_software")
                            value: aboutSettings.vendorName || aboutSettings.vendorVersion
                                   ? aboutSettings.vendorName + " " + aboutSettings.vendorVersion
                                   : "-"
                        }

                        Snippets {
                            folder: "/usr/share/jolla-settings/pages/about/hidden-detail-snippets"
                        }
                    }
                }

                DetailItem {
                    //: Label for the version of the device-specific software package (drivers)
                    //% "Device adaptation"
                    label: qsTrId("settings_about-la-adaptation")
                    value: aboutSettings.adaptationVersion
                }


                DetailItem {
                    //% "WLAN MAC address"
                    label: qsTrId("settings_about-la-wlan_mac_address")
                    value: aboutSettings.wlanMacAddress
                }

                DetailItem {
                    //% "Bluetooth address"
                    label: qsTrId("settings_about-la-bluetooth_address")
                    value: bluetoothInfo.adapterAddress

                    // aboutSettings.bluetoothAddress may be 00:00:00:00:00 if the adapter could not
                    // be initialized at start-up, use BluetoothInfo instead (guarantees a valid address)
                    BluetoothInfo {
                        id: bluetoothInfo
                    }
                }

                Loader {
                    width: parent.width
                    active: encryptionSettings.homeEncrypted
                    source: "HomeEncryption.qml"
                }

                DetailItem {
                    visible: tohInfo.tohReady && value !== ""
                    label: "The Other Half"
                    value: tohInfo.tohId

                    TohInfo {
                        id: tohInfo
                    }
                }

                Snippets {
                    folder: "/usr/share/jolla-settings/pages/about/detail-snippets"
                }
            }

            Snippets {
                folder: "/usr/share/jolla-settings/pages/about/snippets"
            }

            Component {
                id: textSnippet
                Item {
                    height: textItem.height

                    AboutText {
                        id: textItem
                        text: TextFileReader.readContent(path)
                    }
                }
            }
        }

        VerticalScrollDecorator {}
    }
}
