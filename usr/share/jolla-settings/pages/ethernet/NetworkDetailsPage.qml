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
                text: qsTrId("settings_network-me-ethernet-edit")
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
                        return qsTrId("settings_network-la-ethernet-connected_state")
                    case "ready":
                        //% "Limited connectivity"
                        return qsTrId("settings_network-la-ethernet-limited_state")
                    default:
                        //% "Not connected"
                        return qsTrId("settings_network-la-ethernet-not_connected")
                    }
                }
            }

            DetailItem {
                //% "Hardware Address"
                label: qsTrId("settings_network-la-ethernet-hardware_address")
                value: network.ethernet["Address"] || "-"
            }

            // Ethernet does not yet have setting for this but could be added later on
            DetailItem {
                property real speed: network.maxRate/1000000.0
                property string speedString: (speed).toLocaleString(Qt.locale(), 'f', 1)

                //% "Maximum speed"
                label: qsTrId("settings_network-la-ethernet-maximum_speed")

                //: Megabits per second
                //% "%1 Mb/s"
                value: qsTrId("settings_network-la-ethernet-megabits_per_second").arg(speedString)
                visible: speed != 0.0
            }

            Column {
                width: parent.width
                visible: network.ipv4["Address"] !== undefined || network.ipv6["Address"] !== undefined

                SectionHeader {
                    //% "Addresses"
                    text: qsTrId("settings_network-la-ethernet-addresses")
                }

                DetailItem {
                    //% "IPv4 address"
                    label: qsTrId("settings_network-la-ethernet-ipv4_address")
                    value: network.ipv4["Address"]
                    visible: network.ipv4["Address"] !== undefined
                }

                DetailItem {
                    //% "IPv4 Netmask"
                    label: qsTrId("settings_network-la-ethernet-ipv4_netmask")
                    value: network.ipv4["Netmask"] || "-"
                    visible: network.ipv4["Address"] !== undefined
                }

                DetailItem {
                    //% "IPv4 Gateway"
                    label: qsTrId("settings_network-la-ethernet-ipv4_gateway")
                    value: network.ipv4["Gateway"] || "-"
                    visible: network.ipv4["Address"] !== undefined
                }

                DetailItem {
                    //% "IPv6 address"
                    label: qsTrId("settings_network-la-ethernet-ipv6_address")
                    value: network.ipv6["Address"] + "/" + network.ipv6["PrefixLength"]
                    visible: network.ipv6["Address"] !== undefined
                }

                DetailItem {
                    //% "DNS servers"
                    label: qsTrId("settings_network-la-ethernet-dns_servers")
                    value: network.nameservers ? network.nameservers.join("\n") : "-"
                }
            }
        }
        VerticalScrollDecorator { }
    }
}
