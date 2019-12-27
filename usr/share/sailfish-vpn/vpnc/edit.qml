import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Settings.Networking 1.0
import Sailfish.Settings.Networking.Vpn 1.0

VpnPlatformEditDialog {
                           //% "Add new VPNC connection"
    title: newConnection ? qsTrId("settings_network-he-vpn_add_new_vpnc")
                           //% "Edit VPNC connection"
                         : qsTrId("settings_network-he-vpn_edit_vpnc")

    vpnType: "vpnc"
    firstAdditionalItem: vpncIpSecId
    canAccept: validSettings && vpncIpSecId.text.length > 0

    Component.onCompleted: {
        init()
        vpncIpSecId.text = getProviderProperty('VPNC.IPSec.ID')
    }

    onAccepted: {
        updateProvider('VPNC.IPSec.ID', vpncIpSecId.text)
        saveConnection()
    }

    ConfigTextField {
        id: vpncIpSecId

        //% "IPSec identifier"
        label: qsTrId("settings_network-la-vpn_vpnc_ipsec_id")
    }
}

