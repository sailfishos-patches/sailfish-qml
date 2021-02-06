import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Settings.Networking.Vpn 1.0
import Sailfish.Settings.Networking 1.0

VpnTypeItem {
    canImport: true

    //% "VPNC"
    name: qsTrId("settings_network-me-vpn_type_vpnc")
 
    //% "A client for the Cisco 3000 VPN protocol"
    description: qsTrId("settings_network-la-vpn_type_vpnc")
}
