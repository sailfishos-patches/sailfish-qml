import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Settings.Networking.Vpn 1.0
import Sailfish.Settings.Networking 1.0

Column {
    function setProperties(providerProperties) {
        openVpnCert.path = getProperty('OpenVPN.Cert')
        openVpnKey.path = getProperty('OpenVPN.Key')
        openVpnPort.text = getProperty('OpenVPN.Port')
        openVpnProto.setValue(getProperty('OpenVPN.Proto'))
        openVpnCompLZO.setValue(getProperty('OpenVPN.CompLZO'))
        openVpnConfigFile.path = getProperty('OpenVPN.ConfigFile')
        openVpnAskPass.path = getProperty('OpenVPN.AskPass')
        openVpnAuthNoCache.checked = getProperty('OpenVPN.AuthNoCache') === 'true'
        openVpnNSCertType.setValue(getProperty('OpenVPN.NSCertType'))
        openVpnRemoteCertTLS.setValue(getProperty('OpenVPN.RemoteCertTls'))
        openVpnCipher.text = getProperty('OpenVPN.Cipher')
        openVpnDataCiphers.text = getProperty('OpenVPN.DataCiphers')
        openVpnDataCiphersFallback.text = getProperty('OpenVPN.DataCiphersFallback')
        openVpnAuth.text = getProperty('OpenVPN.Auth')
        openVpnMTU.text = getProperty('OpenVPN.MTU')
        openVpnDeviceType.setValue(getProperty('OpenVPN.DeviceType'))
        openVpnPing.text = getProperty('OpenVPN.Ping')
        openVpnPingExit.text = getProperty('OpenVPN.PingExit')
        openVpnRemapUsr.setValue(getProperty('OpenVPN.RemapUsr1'))
        openVpnBlockIPv6.setValue(getProperty('OpenVPN.BlockIPv6'))
        // OpenVPN.TLSRemote deprecated in openvpn 2.3+
    }

    function updateProperties(providerProperties) {
        updateProvider('OpenVPN.Cert', openVpnCert.path)
        updateProvider('OpenVPN.Key', openVpnKey.path)
        updateProvider('OpenVPN.Port', openVpnPort.filteredText)
        updateProvider('OpenVPN.Proto', openVpnProto.selection)
        updateProvider('OpenVPN.CompLZO', openVpnCompLZO.selection)
        updateProvider('OpenVPN.ConfigFile', openVpnConfigFile.path)
        updateProvider('OpenVPN.AskPass', openVpnAskPass.path)
        updateProvider('OpenVPN.AuthNoCache', openVpnAuthNoCache.checked.toString())
        updateProvider('OpenVPN.NSCertType', openVpnNSCertType.selection)
        updateProvider('OpenVPN.RemoteCertTls', openVpnRemoteCertTLS.selection)
        updateProvider('OpenVPN.Cipher', openVpnCipher.text)
        updateProvider('OpenVPN.DataCiphers', openVpnDataCiphers.text)
        updateProvider('OpenVPN.DataCiphersFallback', openVpnDataCiphersFallback.text)
        updateProvider('OpenVPN.Auth', openVpnAuth.text)
        updateProvider('OpenVPN.MTU', openVpnMTU.filteredText)
        updateProvider('OpenVPN.DeviceType', openVpnDeviceType.selection)
        updateProvider('OpenVPN.Ping', openVpnPing.filteredText)
        updateProvider('OpenVPN.PingExit', openVpnPingExit.filteredText)
        updateProvider('OpenVPN.RemapUsr1', openVpnRemapUsr.selection)
        updateProvider('OpenVPN.BlockIPv6', openVpnBlockIPv6.selection)
    }

    width: parent.width

    SectionHeader {
        //: Settings pertaining to the identification of the local user or device
        //% "Credentials"
        text: qsTrId("settings_network-he-vpn_openvpn_credentials")
    }

    ConfigPathField {
        id: openVpnKey

        //% "Private key file"
        label: qsTrId("settings_network-la-vpn_openvpn_key")
    }

    ConfigPathField {
        id: openVpnCert

        //% "Certificate file"
        label: qsTrId("settings_network-la-vpn_openvpn_cert")
    }

    ConfigPathField {
        id: openVpnAskPass

        //% "Certificate password file"
        label: qsTrId("settings_network-la-vpn_openvpn_askpass")
    }

    SectionHeader {
        //: Settings pertaining to the remote server or peer
        //% "Remote server"
        text: qsTrId("settings_network-he-vpn_openvpn_remote_server")
    }

    ConfigComboBox {
        id: openVpnNSCertType

        values: [ "_default", "server", "client" ]

        //% "Require certificate type"
        label: qsTrId("settings_network-la-vpn_openvpn_nscerttype")
    }

    ConfigComboBox {
        id: openVpnRemoteCertTLS

        values: [ "_default", "server", "client" ]

        //% "Require certificate usage"
        label: qsTrId("settings_network-la-vpn_openvpn_remotecerttls")
    }

    SectionHeader {
        //: Settings pertaining to the communication channel
        //% "Communications"
        text: qsTrId("settings_network-he-vpn_openvpn_communications")
    }

    ConfigComboBox {
        id: openVpnProto

        values: [ "_default", "udp", "tcp-client" ]

        //% "Protocol type"
        label: qsTrId("settings_network-la-vpn_openvpn_proto")
    }

    ConfigIntField {
        id: openVpnPort
        intUpperLimit: 65535

        //% "Port"
        label: qsTrId("settings_network-la-vpn_openvpn_port")

        //% "Port must be a value between 1 and 65535"
        description: errorHighlight ? qsTrId("settings_network_la-vpn_openvpn_port_error") : ""
    }

    ConfigComboBox {
        id: openVpnCompLZO

        values: [ "_default", "adaptive", "yes", "no" ]

        //% "LZO compression"
        label: qsTrId("settings_network-la-vpn_openvpn_complzo")
    }

    ConfigIntField {
        id: openVpnMTU
        intUpperLimit: 65535

        //% "Packet MTU size"
        label: qsTrId("settings_network-la-vpn_openvpn_mtu")
        //% "MTU size must be a value between 1 and 65535"
        description: errorHighlight ? qsTrId("settings_network_la-vpn_openvpn_error") : ""
    }

    ConfigIntField {
        id: openVpnPing
        intUpperLimit: 86400

        //% "Interval to ping server (seconds)"
        label: qsTrId("settings_network-la-vpn_openvpn_ping")
        //% "Select server ping interval between 1 and 86400 seconds"
        description: errorHighlight ? qsTrId("settings_network_la-vpn_openvpn_ping_error") : ""
    }

    ConfigIntField {
        id: openVpnPingExit
        intUpperLimit: 86400

        //% "Exit if no ping reply from server (seconds)"
        label: qsTrId("settings_network-la-vpn_openvpn_ping_exit")
        //% "Select exit timeout between 1 and 86400 seconds"
        description: errorHighlight ? qsTrId("settings_network_la-vpn_openvpn_ping_exit_error") : ""
    }

    ConfigComboBox {
        id: openVpnRemapUsr

        values: [ "_default", "SIGTERM", "SIGHUP" ]

        //% "Remap restart signal to"
        label: qsTrId("settings_network-la-vpn_openvpn_restart_on_comm_error")
    }

    SectionHeader {
        //: Settings pertaining to the communication security
        //% "Security"
        text: qsTrId("settings_network-he-vpn_openvpn_security")
    }

    ConfigComboBox {
        id: openVpnBlockIPv6

        values: [ "_default", "true", "false" ]

        //: Disabling IPv6 enables data leak protection
        //% "Disable IPv6"
        label: qsTrId("settings_network-la-vpn_openvpn_disable_ipv6")
    }

    ConfigTextField {
        id: openVpnCipher

        //% "Cipher algorithm"
        label: qsTrId("settings_network-la-vpn_openvpn_cipher")
        nextFocusItem: openVpnDataCiphers
    }

     ConfigTextField {
        id: openVpnDataCiphers

        //% "Available cipher algorithms to use"
        label: qsTrId("settings_network-la-vpn_openvpn_data_ciphers")
        nextFocusItem: openVpnDataCiphersFallback
    }

    ConfigTextField {
        id: openVpnDataCiphersFallback

        //% "Fallback cipher algorithm"
        label: qsTrId("settings_network-la-vpn_openvpn_data_ciphers_fallback")
        nextFocusItem: openVpnAuth
    }

    ConfigTextField {
        id: openVpnAuth

        //% "Digest algorithm"
        label: qsTrId("settings_network-la-vpn_openvpn_auth")
    }

    SectionHeader {
        //: Settings pertaining to the openvpn service on the local device
        //% "OpenVPN service"
        text: qsTrId("settings_network-he-vpn_openvpn_service")
    }

    ConfigPathField {
        id: openVpnConfigFile

        //% "Configuration file"
        label: qsTrId("settings_network-la-vpn_openvpn_configfile")
    }

    ConfigComboBox {
        id: openVpnDeviceType

        values: [ "_default", "tun", "tap" ]

        //% "Device type"
        label: qsTrId("settings_network-la-vpn_openvpn_device_type")
    }

    TextSwitch {
        id: openVpnAuthNoCache

        //% "Prevent caching credentials"
        text: qsTrId("settings_network-la-vpn_openvpn_authnocache")
    }
}
