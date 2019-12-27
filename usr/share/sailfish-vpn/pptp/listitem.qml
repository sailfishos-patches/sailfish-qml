import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Settings.Networking.Vpn 1.0
import Sailfish.Settings.Networking 1.0

VpnTypeItem {
    vpnType: "pptp"

    //% "PPTP"
    name: qsTrId("settings_network-me-vpn_type_pptp")
 
    //% "A client for the Point-to-Point Tunneling protocol"
    description: qsTrId("settings_network-la-vpn_type_pptp")
}
