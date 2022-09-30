import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Settings.Networking.Vpn 1.0
import Sailfish.Settings.Networking 1.0

Column {
    function setProperties(providerProperties) {
        vpncIkeAuthMode.setValue(getProperty('VPNC.IKE.Authmode'))
        vpncIkeDhGroup.setValue(getProperty('VPNC.IKE.DHGroup'))
        vpncPfsDhGroup.setValue(getProperty('VPNC.PFS'))
        vpncDomain.text = getProperty('VPNC.Domain')
        vpncVendor.setValue(getProperty('VPNC.Vendor'))
        vpncLocalPort.text = getProperty('VPNC.LocalPort')
        vpncCiscoPort.text = getProperty('VPNC.CiscoPort')
        vpncAppVersion.text = getProperty('VPNC.AppVersion')
        vpncNattMode.setValue(getProperty('VPNC.NATTMode'))
        var timeout = getProperty('VPNC.DPDTimeout')
        vpncUseTimeout.checked = timeout && timeout !== '0'
        vpncDpdTimeout.text = timeout
        vpncSingleDES.checked = getProperty('VPNC.SingleDES') === 'true'
        vpncNoEncryption.checked = getProperty('VPNC.NoEncryption') === 'true'
        vpncBlockIPv6.checked = getProperty('VPNC.BlockIPv6') === 'true'
        vpncDeviceType.setValue(getProperty('VPNC.DeviceType'))
    }

    function updateProperties(providerProperties) {
        updateProvider('VPNC.IKE.Authmode', vpncIkeAuthMode.selection)
        updateProvider('VPNC.IKE.DHGroup', vpncIkeDhGroup.selection)
        updateProvider('VPNC.PFS', vpncPfsDhGroup.selection)
        updateProvider('VPNC.Domain', vpncDomain.text)
        updateProvider('VPNC.Vendor', vpncVendor.selection)
        updateProvider('VPNC.LocalPort', vpncLocalPort.filteredText)
        updateProvider('VPNC.CiscoPort', vpncCiscoPort.filteredText)
        updateProvider('VPNC.AppVersion', vpncAppVersion.text)
        updateProvider('VPNC.NATTMode', vpncNattMode.selection)
        updateProvider('VPNC.DPDTimeout', vpncUseTimeout.checked ? vpncDpdTimeout.filteredText : '')
        updateProvider('VPNC.SingleDES', vpncSingleDES.checked.toString())
        updateProvider('VPNC.NoEncryption', vpncNoEncryption.checked.toString())
        updateProvider('VPNC.BlockIPv6', vpncBlockIPv6.checked.toString())
        updateProvider('VPNC.DeviceType', vpncDeviceType.selection)
    }

    width: parent.width

    /* TODO enable these when the values are retrieved from VPN agent
    SectionHeader {
        //: Settings pertaining to the identification of the local user or device
        //% "Credentials"
        text: qsTrId("settings_network-he-vpn_vpnc_credentials")
    }

    ConfigPasswordField {
        id: vpncIpSecSecret

        //% "IPSec secret"
        label: qsTrId("settings_network-la-vpn_vpnc_ipsec_secret")
        nextFocusItem: vpncXauthUsername
    }

    ConfigTextField {
        id: vpncXauthUsername

        //% "XAUTH user name"
        label: qsTrId("settings_network-la-vpn_vpnc_xauth_username")
        nextFocusItem: vpncXauthPassword
    }

    ConfigPasswordField {
        id: vpncXauthPassword

        //% "XAUTH password"
        label: qsTrId("settings_network-la-vpn_vpnc_xauth_password")
    }*/

    SectionHeader {
        //: Settings pertaining to the remote server or peer
        //% "Remote server"
        text: qsTrId("settings_network-he-vpn_vpnc_remote_server")
    }

    ConfigComboBox {
        id: vpncVendor

        values: [ "_default", "cisco", "netscreen" ]

        //% "Gateway vendor"
        label: qsTrId("settings_network-la-vpn_vpnc_vendor")
    }

    SectionHeader {
        //: Settings pertaining to the authentication procedure
        //% "Authentication"
        text: qsTrId("settings_network-he-vpn_vpnc_authentication")
    }

    ConfigComboBox {
        id: vpncIkeAuthMode

        values: [ "_default", "psk", "cert", "hybrid" ]

        //% "Mode for IKE"
        label: qsTrId("settings_network-la-vpn_vpnc_ike_auth_mode")
    }

    ConfigComboBox {
        id: vpncIkeDhGroup

        values: [ "_default", "dh1", "dh2", "dh5" ]

        //% "DH group for IKE"
        label: qsTrId("settings_network-la-vpn_vpnc_ike_dh_group")
    }

    ConfigComboBox {
        id: vpncPfsDhGroup

        values: [ "_default", "nopfs", "dh1", "dh2", "dh5", "server" ]

        //% "DH group for PFS"
        label: qsTrId("settings_network-la-vpn_vpnc_pfs_dh_group")
    }

    ConfigTextField {
        id: vpncDomain

        //% "Domain"
        label: qsTrId("settings_network-la-vpn_vpnc_domain")
    }

    SectionHeader {
        //: Settings pertaining to the communication channel
        //% "Communications"
        text: qsTrId("settings_network-he-vpn_vpnc_communications")
    }

    ConfigComboBox {
        id: vpncNattMode

        values: [ "_default", "none", "natt", "force-natt", "cisco-udp" ]

        //% "NAT traversal mode"
        label: qsTrId("settings_network-la-vpn_vpnc_natt_mode")
    }

    TextSwitch {
        id: vpncSingleDES

        //% "Enable single DES"
        text: qsTrId("settings_network-la-vpn_vpnc_single_des")
    }

    TextSwitch {
        id: vpncNoEncryption

        //% "Enable no encryption"
        text: qsTrId("settings_network-la-vpn_vpnc_no_encryption")
    }

    TextSwitch {
        id: vpncBlockIPv6

        //% "Enable IPv6 data leak protection"
        text: qsTrId("settings_network-la-vpn_vpnc_enable_ipv6_data_leak_protection")
    }

    TextSwitch {
        id: vpncUseTimeout

        //% "Enable DPD timeout"
        text: qsTrId("settings_network-la-vpn_vpnc_use_dpd_timeout")
    }

    ConfigIntField {
        id: vpncDpdTimeout
        visible: vpncUseTimeout.checked

        intLowerLimit: 10
        intUpperLimit: 86400

        //% "DPD timeout seconds"
        label: qsTrId("settings_network-la-vpn_vpnc_dpd_timeout")
        //% "Select timeout between 10 and 86400 seconds"
        description: errorHighlight ? qsTrId("settings_network_la_vpn_vpnc_dpd_timeout_error") : ""
    }

    SectionHeader {
        //: Settings pertaining to the vpnc service on the local device
        //% "VPNC service"
        text: qsTrId("settings_network-he-vpn_vpnc_service")
    }

    ConfigComboBox {
        id: vpncDeviceType

        values: [ "_default", "tun", "tap" ]

        //% "Device type"
        label: qsTrId("settings_network-la-vpn_vpnc_device_type")
    }

    ConfigIntField {
        id: vpncLocalPort
        intUpperLimit: 65535

        //% "ISAKMP port"
        label: qsTrId("settings_network-la-vpn_vpnc_local_port")
        //% "Port number must be a value between 1 and 65535"
        description: errorHighlight ? qsTrId("settings_network_la-vpn_vpnc_local_port_error") : ""

        nextFocusItem: vpncCiscoPort
    }

    ConfigIntField {
        id: vpncCiscoPort
        intUpperLimit: 65535

        //% "Cisco port"
        label: qsTrId("settings_network-la-vpn_vpnc_cisco_port")
        //% "Port number must be a value between 1 and 65535"
        description: errorHighlight ? qsTrId("settings_network_la-vpn_vpnc_cisco_port_error") : ""

        nextFocusItem: vpncAppVersion
    }

    ConfigTextField {
        id: vpncAppVersion

        //% "Application version"
        label: qsTrId("settings_network-la-vpn_vpnc_appversion")
    }
}

