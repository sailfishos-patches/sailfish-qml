import QtQuick 2.0
import Sailfish.Silica 1.0
import Connman 0.2
import Sailfish.Settings.Networking 1.0

Page {
    id: detailsPage
    property QtObject network
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem {
                //% "Edit"
                text: qsTrId("settings_network-me-edit")
                onClicked: pageStack.animatorPush("AdvancedSettingsPage.qml", {"network": network})
            }
        }

        Column {
            id: column
            width: parent.width

            PageHeader {
                title: network.name
            }

            SectionHeader {
                text: {
                    switch (network.state) {
                    case "online":
                        //% "Connected"
                        return qsTrId("settings_network-la-connected_state")
                    case "ready":
                        //% "Limited connectivity"
                        return qsTrId("settings_network-la-limited_state")
                    default:
                        //% "Not connected"
                        return qsTrId("settings_network-la-not_connected")
                    }
                }
            }

            DetailItem {
                //% "Hardware Address"
                label: qsTrId("settings_network-la-hardware_address")
                value: network.ethernet["Address"] || "-"
            }

            DetailItem {
                //% "Security"
                label: qsTrId("settings_network-la-security")

                value: WlanUtils.getEncryptionString(network.securityType, network.eapMethod)
                visible: value.length > 0
            }

            DetailItem {
                //% "PEAP version"
                label: qsTrId("settings_network-la-peap_version")
                value: {
                    switch (network.peapVersion) {
                    case -1:
                        //% "Automatic"
                        return qsTrId("settings_network-va-encryption_peap_automatic")
                    case 0:
                        //% "Version 0"
                        return qsTrId("settings_network-va-encryption_version0")
                    case 1:
                        //% "Version 1"
                        return qsTrId("settings_network-va-encryption_version1")
                    }
                }
                visible: network && network.securityType === NetworkService.SecurityIEEE802 && network.eapMethod === NetworkService.EapPEAP
            }

            DetailItem {
                //: Method used inside PEAP/TTLS tunnel to authenticate user, most commonly MSCHAPv2
                //% "Inner authentication"
                label: qsTrId("settings_network-la-eap_inner_authentication")

                value: network.phase2
                visible: network && network.securityType === NetworkService.SecurityIEEE802
            }

            DetailItem {
                //% "Signal strength"
                label: qsTrId("settings_network-la-signal_strength")
                value: {
                    var strength = WlanUtils.getStrengthString(network.strength)
                    switch (strength) {
                        case "no-signal":
                            //% "No signal (%1 %)"
                            return qsTrId("settings_network-la-no-signal").arg(network.strength)
                        case "0":
                            //% "Weak (%1 %)"
                            return qsTrId("settings_network-la-weak").arg(network.strength)
                        case "1":
                            //% "Moderate (%1 %)"
                            return qsTrId("settings_network-la-moderate").arg(network.strength)
                        case "2":
                            //% "Fair (%1 %)"
                            return qsTrId("settings_network-la-fair").arg(network.strength)
                        case "3":
                            //% "Good (%1 %)"
                            return qsTrId("settings_network-la-good").arg(network.strength)
                        case "4":
                            //% "Excellent (%1 %)"
                            return qsTrId("settings_network-la-excellent").arg(network.strength)
                    }
                }
                visible: value.length > 0
            }

            DetailItem {
                property real speed: network.maxRate/1000000.0
                property string speedString: (speed).toLocaleString(Qt.locale(), 'f', 1)

                //% "Maximum speed"
                label: qsTrId("settings_network-la-maximum_speed")

                //: Megabits per second
                //% "%1 Mb/s"
                value: qsTrId("settings_network-la-megabits_per_second").arg(speedString)
                visible: speed != 0.0
            }

            DetailItem {
                property string frequency: parseFloat(network.frequency/1000.0).toFixed(1).toString()

                //% "Frequency"
                label: qsTrId("settings_network-la-frequency")

                //: Gigahertz
                //% "%1 GHz"
                value: qsTrId("settings_network-la-gigahertz").arg(frequency)
                visible: network.frequency > 0.0
            }

            Column {
                width: parent.width
                visible: network.ipv4["Address"] !== undefined || network.ipv6["Address"] !== undefined

                SectionHeader {
                    //% "Addresses"
                    text: qsTrId("settings_network-la-addresses")
                }

                DetailItem {
                    //% "BSSID"
                    label: qsTrId("settings_network-la-bssid")
                    value: network.bssid
                    visible: value.length > 0
                }

                DetailItem {
                    //% "IPv4 address"
                    label: qsTrId("settings_network-la-ipv4_address")
                    value: network.ipv4["Address"]
                    visible: network.ipv4["Address"] !== undefined
                }

                DetailItem {
                    //% "IPv4 Netmask"
                    label: qsTrId("settings_network-la-ipv4_netmask")
                    value: network.ipv4["Netmask"] || "-"
                    visible: network.ipv4["Address"] !== undefined
                }

                DetailItem {
                    //% "IPv4 Gateway"
                    label: qsTrId("settings_network-la-ipv4_gateway")
                    value: network.ipv4["Gateway"] || "-"
                    visible: network.ipv4["Address"] !== undefined
                }

                DetailItem {
                    //% "IPv6 address"
                    label: qsTrId("settings_network-la-ipv6_address")
                    value: network.ipv6["Address"] + "/" + network.ipv6["PrefixLength"]
                    visible: network.ipv6["Address"] !== undefined
                }

                DetailItem {
                    //% "DNS servers"
                    label: qsTrId("settings_network-la-dns_servesr")
                    value: network.nameservers ? network.nameservers.join("\n") : "-"
                }
            }
        }
        VerticalScrollDecorator { }
    }
}
