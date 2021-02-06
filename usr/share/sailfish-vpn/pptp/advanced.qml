import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Settings.Networking.Vpn 1.0
import Sailfish.Settings.Networking 1.0

Column {
    property string defaultText

    function setProperties(providerProperties) {
        pptpUser.text = getProperty('PPTP.User')
        pptpIdleWait.text = getProperty('PPTP.IdleWait')
        pptpMaxEchoWait.text = getProperty('PPTP.MaxEchoWait')

        pppdOptions.setProperties(providerProperties)
    }

    function updateProperties(providerProperties) {
        updateProvider('PPTP.User', pptpUser.text)
        updateProvider('PPTP.IdleWait', pptpIdleWait.filteredText)
        updateProvider('PPTP.MaxEchoWait', pptpMaxEchoWait.filteredText)

        pppdOptions.updateProperties(providerProperties)
    }

    width: parent.width

    SectionHeader {
        //: Settings pertaining to the identification of the local user or device
        //% "Credentials"
        text: qsTrId("settings_network-he-vpn_pptp_credentials")
    }

    ConfigTextField {
        id: pptpUser

        //% "User name"
        label: qsTrId("settings_network-la-vpn_pptp_user")
    }

    SectionHeader {
        //% "Communications"
        text: qsTrId("settings_network-he-vpn_pptp_communications")
    }

    ConfigIntField {
        id: pptpIdleWait
        intUpperLimit: 86400

        //: Time to wait before sending a control connection echo request
        //% "Echo request delay (seconds)"
        label: qsTrId("settings_network_la_vpn_pptp_idle_wait")
        //% "Select delay between 1 and 86400 seconds"
        description: errorHighlight ? qsTrId("settings_network_la-vpn_pptp_idle_wait_error") : ""
    }


    ConfigIntField {
        id: pptpMaxEchoWait
        intUpperLimit: 86400

        //: Time to wait for an echo reply before closing the control connection
        //% "Connection timeout (seconds)"
        label: qsTrId("settings_network_la_vpn_pptp_max_echo_wait")
        //% "Select timeout between 1 and 86400 seconds"
        description: errorHighlight ? qsTrId("settings_network_la-vpn_pptp_max_echo_wait_error") : ""
    }

    PPPD {
        id: pppdOptions
    }
}
