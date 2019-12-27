import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Settings.Networking 1.0
import Sailfish.Settings.Networking.Vpn 1.0

VpnPlatformEditDialog {
                           //% "Add new L2TP connection"
    title: newConnection ? qsTrId("settings_network-he-vpn_add_new_l2tp")
                           //% "Edit L2TP connection"
                         : qsTrId("settings_network-he-vpn_edit_l2tp")

    vpnType: "l2tp"

    onAccepted: saveConnection()
    Component.onCompleted: init()
}

