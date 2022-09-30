import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Settings.Networking 1.0
import Sailfish.Settings.Networking.Vpn 1.0

VpnPlatformEditDialog {
    //% "Add new PPTP connection"
    newTitle: qsTrId("settings_network-he-vpn_add_new_pptp")
    //% "PPTP set up is ready!"
    importTitle: qsTrId("settings_network-he-vpn_import_pptp_success")
    //% "Edit PPTP connection"
    editTitle: qsTrId("settings_network-he-vpn_edit_pptp")

    Binding on subtitle {
        when: newConnection && importPath

        //% "Settings have been imported. You can change the settings now or later after saving the"
        //% " connection. If username and password are required, they will be requested after turning"
        //% " on the connection."
        value: qsTrId("settings_network-he-vpn_import_openvpn_message")
    }

    onAccepted: saveConnection()
    Component.onCompleted: init()
}

