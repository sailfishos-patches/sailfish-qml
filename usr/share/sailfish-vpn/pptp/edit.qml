import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Settings.Networking 1.0
import Sailfish.Settings.Networking.Vpn 1.0

VpnPlatformEditDialog {
                           //% "Add new PPTP connection"
    title: newConnection ? qsTrId("settings_network-he-vpn_add_new_pptp")
                           //% "Edit PPTP connection"
                         : qsTrId("settings_network-he-vpn_edit_pptp")

    vpnType: "pptp"

    onAccepted: saveConnection()
    Component.onCompleted: init()
}

