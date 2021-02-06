import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Settings.Networking 1.0
import Sailfish.Settings.Networking.Vpn 1.0

VpnPlatformEditDialog {
    //% "Add new VPNC connection"
    newTitle: qsTrId("settings_network-he-vpn_add_new_vpnc")
    //% "VPNC set up is ready!"
    importTitle: qsTrId("settings_network-he-vpn_import_vpnc_success")
    //% "Edit VPNC connection"
    editTitle: qsTrId("settings_network-he-vpn_edit_vpnc")

    firstAdditionalItem: vpncIpSecId
    canAccept: validSettings && vpncIpSecId.acceptableInput

    Binding on subtitle {
        when: newConnection && importPath

        //% "Settings have been imported. You can change the settings now or later after saving the"
        //% " connection. If username and password are required, they will be requested after turning"
        //% " on the connection."
        value: qsTrId("settings_network-he-vpn_import_openvpn_message")
    }


    Component.onCompleted: {
        init()
        vpncIpSecId.text = getProviderProperty('VPNC.IPSec.ID')
    }

    onAccepted: {
        updateProvider('VPNC.IPSec.ID', vpncIpSecId.text)
        saveConnection()
    }
    onAcceptBlocked: {
        if (!vpncIpSecId.acceptableInput) {
            vpncIpSecId.errorHighlight = true
        }
    }

    ConfigTextField {
        id: vpncIpSecId

        //% "IPSec identifier"
        label: qsTrId("settings_network-la-vpn_vpnc_ipsec_id")

        acceptableInput: text.length > 0
        onActiveFocusChanged: if (!activeFocus) errorHighlight = !acceptableInput
        onAcceptableInputChanged: if (acceptableInput) errorHighlight = false

        //% "IPSec identifier is required"
        description: errorHighlight ? qsTrId("settings_network_la-vpn_vpnc_ipsec_id_error") : ""
    }
}

