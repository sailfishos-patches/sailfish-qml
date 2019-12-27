import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Settings.Networking.Vpn 1.0
import Sailfish.Settings.Networking 1.0

VpnTypeItem {
    vpnType: "openconnect"

    //% "OpenConnect"
    name: qsTrId("settings_network-me-vpn_type_openconnect")
 
    //% "A VPN implementation using the AnyConnect protocol"
    description: qsTrId("settings_network-la-vpn_type_openconnect")
}
