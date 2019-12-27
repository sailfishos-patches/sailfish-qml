import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Settings.Networking.Vpn 1.0
import Sailfish.Settings.Networking 1.0

VpnTypeItem {
    handleClick: false
    vpnType: "openvpn"
    onClicked: {
        pageStack.animatorPush("OvpnFileSettingsDialog.qml", { mainPage: _mainPage })
    }

    //% "OpenVPN"
    name: qsTrId("settings_network-me-vpn_type_openvpn")

    //% "A modern VPN implementation using SSL/TLS for key exchange"
    description: qsTrId("settings_network-la-vpn_type_openvpn")
}
