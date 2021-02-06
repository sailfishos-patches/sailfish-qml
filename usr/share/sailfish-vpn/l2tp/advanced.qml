import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Settings.Networking 1.0
import Sailfish.Settings.Networking.Vpn 1.0

Column {
    property string defaultText

    function setProperties(providerProperties) {
        var getYesProperty = function(name, default_value) {
            if (getProperty(name) === 'yes') {
                return true
            } else if (getProperty(name) === 'no') {
                return false
            }
            return !!default_value
        }

        l2tpPort.text = getProperty('L2TP.Port')
        l2tpListenAddress.text = getProperty('L2TP.ListenAddr')
        l2tpAuthFile.path = getProperty('L2TP.AuthFile')
        l2tpIPsecSaref.checked = getYesProperty('L2TP.IPsecSaref')
        // By default CHAP is being set in config if value is omitted
        if (getYesProperty('L2TP.RequireCHAP', true)) {
            l2tpReqAuth.setValue('auth-chap-required')
        } else if (getYesProperty('L2TP.RequirePAP')) {
            l2tpReqAuth.setValue('auth-pap-required')
        } else if (getYesProperty('L2TP.ReqAuth')) {
            l2tpReqAuth.setValue('auth-required')
        } else {
            l2tpReqAuth.setValue('no-auth')
        }
        l2tpChallenge.checked = getYesProperty('L2TP.Challenge')
        //l2tpAccessControl.checked = getYesProperty('L2TP.AccessControl')
        l2tpExclusive.checked = getYesProperty('L2TP.Exclusive')
        l2tpDefaultRoute.checked = getYesProperty('L2TP.DefaultRoute')
        l2tpLengthBit.checked = getYesProperty('L2TP.LengthBit')
        l2tpFlowBit.checked = getYesProperty('L2TP.FlowBit')
        l2tpTunnelRWS.text = getProperty('L2TP.TunnelRWS')
        // By default, redial is set if value is omitted, empty yes
        l2tpRedial.checked = getYesProperty('L2TP.Redial', true)
        l2tpRedialTimeout.text = getProperty('L2TP.RedialTimeout') || '10'
        l2tpMaxRedials.text = getProperty('L2TP.MaxRedials')
        l2tpTxBPS.text = getProperty('L2TP.TXBPS')
        l2tpRxBPS.text = getProperty('L2TP.RXBPS')

        pppdOptions.setProperties(providerProperties)
    }

    function updateProperties(providerProperties) {
        updateProvider('L2TP.Port', l2tpPort.filteredText)
        updateProvider('L2TP.ListenAddr', l2tpListenAddress.text)
        updateProvider('L2TP.AuthFile', l2tpAuthFile.path)
        updateProvider('L2TP.IPsecSaref', l2tpIPsecSaref.checked ? 'yes' : 'no')
        updateProvider('L2TP.ReqAuth', l2tpReqAuth.currentIndex === 1 ? 'yes' : 'no')
        updateProvider('L2TP.RequirePAP', l2tpReqAuth.currentIndex === 2 ? 'yes' : 'no')
        updateProvider('L2TP.RequireCHAP', l2tpReqAuth.currentIndex === 3 ? 'yes' : 'no')
        updateProvider('L2TP.Challenge', l2tpChallenge.checked ? 'yes' : 'no')

        /*
        if (l2tpAccessControl.checked) {
            updateProvider('L2TP.AccessControl', 'yes')
        }
        */
        updateProvider('L2TP.Exclusive', l2tpExclusive.checked ? 'yes' : 'no')
        updateProvider('L2TP.DefaultRoute', l2tpDefaultRoute.checked ? 'yes' : 'no')
        updateProvider('L2TP.LengthBit', l2tpLengthBit.checked ? 'yes' : 'no')
        updateProvider('L2TP.FlowBit', l2tpFlowBit.checked ? 'yes' : 'no')
        updateProvider('L2TP.TunnelRWS', l2tpTunnelRWS.text)
        updateProvider('L2TP.Redial', l2tpRedial.checked ? 'yes' : 'no')
        updateProvider('L2TP.RedialTimeout', l2tpRedialTimeout.filteredText)
        updateProvider('L2TP.MaxRedials', l2tpMaxRedials.filteredText)
        updateProvider('L2TP.TXBPS', l2tpTxBPS.filteredText)
        updateProvider('L2TP.RXBPS', l2tpRxBPS.filteredText)

        pppdOptions.updateProperties(providerProperties)
    }

    width: parent.width

    SectionHeader {
        //: Settings pertaining to the authentication procedure
        //% "Authentication"
        text: qsTrId("settings_network-he-vpn_l2tp_authentication")
    }

    ConfigPathField {
        id: l2tpAuthFile

        //% "Authentication file"
        label: qsTrId("settings_network-la-vpn_l2tp_auth_file")
    }

    TextSwitch {
        id: l2tpIPsecSaref

        //% "Use IPsec SA tracking"
        text: qsTrId("settings_network-la-vpn_l2tp_ipsecsaref")
    }

    TextSwitch {
        id: l2tpChallenge

        //% "Use challenge authentication"
        text: qsTrId("settings_network-la-vpn_l2tp_challenge")
    }

    ConfigComboBox {
        id: l2tpReqAuth

        values: [ 'no-auth', 'auth-required', 'auth-pap-required', 'auth-chap-required' ]

        //% "Peer Authentication"
        label: qsTrId("settings_network-la-vpn_l2tp_req_auth")
    }

    /* Not currently implemented, as we need a mechanism to define the acceptable addresses
    TextSwitch {
        id: l2tpAccessControl

        //% "Access Control"
        text: qsTrId("settings_network-la-vpn_l2tp_access_control")
    }
    */

    SectionHeader {
        //: Settings pertaining to the communication channel
        //% "Communications"
        text: qsTrId("settings_network-he-vpn_l2tp_communications")
    }

    TextSwitch {
        id: l2tpLengthBit

        //% "Use length bit"
        text: qsTrId("settings_network-la-vpn_l2tp_length_bit")
    }

    TextSwitch {
        id: l2tpFlowBit

        //% "Use flow bit"
        text: qsTrId("settings_network-la-vpn_l2tp_flow_bit")
    }

    ConfigIntField {
        id: l2tpTunnelRWS
        intUpperLimit: 65535

        //% "Window size"
        label: qsTrId("settings_network-la-vpn_l2tp_tunnel_rws")
        //% "Window size must be a value between 1 and 65535"
        description: errorHighlight ? qsTrId("settings_network_la-vpn_l2tp_tunnel_rws_error") : ""

        nextFocusItem: l2tpTxBPS
    }

    ConfigIntField {
        id: l2tpTxBPS

        //% "Maximum receive bits/second"
        label: qsTrId("settings_network-la-vpn_l2tp_tx_bps")
        nextFocusItem: l2tpRxBPS

        //% "Maximum receiving speed must be above 0"
        description: errorHighlight ? qsTrId("settings_network_la-vpn_l2tp_tx_bps_error") : ""
    }

    ConfigIntField {
        id: l2tpRxBPS

        //% "Maximum transmit bits/second"
        label: qsTrId("settings_network-la-vpn_l2tp_rx_bps")
        nextFocusItem: l2tpPort

        //% "Maximum transmit speed must be above 0"
        description: errorHighlight ? qsTrId("settings_network_la-vpn_l2tp_rx_bps_error") : ""
    }

    SectionHeader {
        //: Settings pertaining to the l2tp service on the local device
        //% "L2TP service"
        text: qsTrId("settings_network-he-vpn_l2tp_service")
    }

    ConfigIntField {
        id: l2tpPort
        intLowerLimit: 1024
        intUpperLimit: 65535

        //% "Listen port"
        label: qsTrId("settings_network-la-vpn_l2tp_port")
        //% "Listen port must be a value between 1024 and 65535"
        description: errorHighlight ? qsTrId("settings_network_la-vpn_l2tp_port_error") : ""

        nextFocusItem: l2tpListenAddress
    }

    ConfigPasswordField {
        id: l2tpListenAddress

        //% "Listen address"
        label: qsTrId("settings_network-la-vpn_l2tp_listen_address")
    }

    TextSwitch {
        id: l2tpExclusive

        //% "Ensure exclusive instance"
        text: qsTrId("settings_network-la-vpn_l2tp_exclusive")
    }

    TextSwitch {
        id: l2tpDefaultRoute

        //% "Set as default route"
        text: qsTrId("settings_network-la-vpn_l2tp_default_route")
    }

    SectionHeader {
        //% "Redial"
        text: qsTrId("settings_network-he-vpn_l2tp_redial")
    }

    TextSwitch {
        id: l2tpRedial

        //% "Redial on disconnect"
        text: qsTrId("settings_network-la-vpn_l2tp_redial")
    }

    Column {
        width: parent.width
        enabled: l2tpRedial.checked
        opacity: enabled ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation {}}
        height: opacity * implicitHeight

        ConfigIntField {
            id: l2tpRedialTimeout
            intUpperLimit: 86400

            //% "Seconds before redial"
            label: qsTrId("settings_network-la-vpn_l2tp_redial_timeout")
            //% "Select redial waiting time between 1 and 86400 seconds"
            description: errorHighlight ? qsTrId("settings_network_la-vpn_l2tp_redial_timeout_error") : ""

            nextFocusItem: l2tpMaxRedials
        }

        ConfigIntField {
            id: l2tpMaxRedials
            intUpperLimit: 1024

            //% "Maximum attempts"
            label: qsTrId("settings_network-la-vpn_l2tp_max_redials")
        }
    }

    PPPD {
        id: pppdOptions
    }
}
