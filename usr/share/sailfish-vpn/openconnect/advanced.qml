import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Settings.Networking 1.0
import Sailfish.Settings.Networking.Vpn 1.0

Column {
    function setProperties(providerProperties) {
        var getProperty = function(name) {
            if (providerProperties) {
                return providerProperties[name] || ''
            }
            return ''
        }

        openConnectServerCert.text = getProperty('OpenConnect.ServerCert')
        openConnectVPNHost.text = getProperty('OpenConnect.VPNHost')
        openConnectCACert.path = getProperty('OpenConnect.CACert')
        openConnectAllowSelfSignedCert.checked = getProperty('OpenConnect.AllowSelfSignedCert') === 'true'
        var protocol = getProperty('OpenConnect.Protocol')
        switch (protocol) {
        case 'anyconnect':
            openConnectProtocol.currentIndex = 0
            break
        case 'nc':
            openConnectProtocol.currentIndex = 1
            break
        case 'gp':
            openConnectProtocol.currentIndex = 2
            break
        default:
            openConnectProtocol.currentIndex = 0
        }
        openConnectMTU.text = getProperty('VPN.MTU')
        openConnectDisableIPv6.checked = getProperty('OpenConnect.DisableIPv6') === 'true'
        openConnectNoHTTPKeepAlive.checked = getProperty('OpenConnect.NoHTTPKeepalive') === 'true'
        openConnectNoDTLS.checked = getProperty('OpenConnect.NoDTLS') === 'true'
    }

    function updateProperties(providerProperties) {
        var updateProvider = function(name, value) {
            // If the value is empty/default, do not include the property in the configuration
            if (value != '' && value != '_default') {
                providerProperties[name] = value
            }
        }

        updateProvider('OpenConnect.ServerCert', openConnectServerCert.text)
        updateProvider('OpenConnect.VPNHost', openConnectVPNHost.text)
        updateProvider('OpenConnect.CACert', openConnectCACert.path)
        updateProvider('OpenConnect.AllowSelfSignedCert', openConnectAllowSelfSignedCert.checked.toString())

        switch (openConnectProtocol.currentIndex) {
        case 0:
            updateProvider('OpenConnect.Protocol', 'anyconnect')
            break
        case 1:
            updateProvider('OpenConnect.Protocol', 'nc')
            break
        case 2:
            updateProvider('OpenConnect.Protocol', 'gp')
            break
        }

        updateProvider('VPN.MTU', openConnectMTU.text)
        updateProvider('OpenConnect.DisableIPv6', openConnectDisableIPv6.checked.toString())
        updateProvider('OpenConnect.NoHTTPKeepalive', openConnectNoHTTPKeepAlive.checked.toString())
        updateProvider('OpenConnect.NoDTLS', openConnectNoDTLS.checked.toString())
    }

    width: parent.width

    SectionHeader {
        //: Settings pertaining to the remote server or peer
        //% "Remote server"
        text: qsTrId("settings_network-he-vpn_openconnect_remote_server")
    }

    ConfigTextField {
        id: openConnectServerCert

        //% "Certificate hash"
        label: qsTrId("settings_network-la-vpn_openconnect_servercert")
        nextFocusItem: openConnectVPNHost
    }

    ConfigPathField {
        id: openConnectCACert

        //% "CA keys file"
        label: qsTrId("settings_network-la-vpn_openconnect_cacert")
    }

    ConfigTextField {
        id: openConnectVPNHost

        //% "Server after authentication"
        label: qsTrId("settings_network-la-vpn_openconnect_vpnhost")
        nextFocusItem: openConnectMTU
    }

    TextSwitch {
        id: openConnectAllowSelfSignedCert

        //% "Allow self signed certificate"
        text: qsTrId("settings_network-la-vpn_openconnect_allow_self_signed_certificate")
    }

    SectionHeader {
        //: Settings pertaining to the communication channel
        //% "Communications"
        text: qsTrId("settings_network-he-vpn_openconnect_communications")
    }

    ComboBox {
        id: openConnectProtocol

        //% "Protocol"
        label: qsTrId("settings_network-la-vpn_openconnect_protocol")
        menu: ContextMenu {
            //% "AnyConnect (default)"
            MenuItem { text: qsTrId("settings_network-la-vpn_openconnect_protocol_anyconnect") }
            //% "Network Connect / Pulse Secure"
            MenuItem { text: qsTrId("settings_network-la-vpn_openconnect_protocol_network_connect") }
            //% "GlobalProtect"
            MenuItem { text: qsTrId("settings_network-la-vpn_openconnect_protocol_type_globalprotect") }
        }
    }

    ConfigTextField {
        id: openConnectMTU

        //% "Packet MTU size"
        label: qsTrId("settings_network-la-vpn_openconnect_mtu")
        inputMethodHints: Qt.ImhDigitsOnly
    }

    TextSwitch {
        id: openConnectDisableIPv6

        //% "Do not ask for IPv6 connectivity"
        text: qsTrId("settings_network-la-vpn_openconnect_disable_IPv6")
    }

    TextSwitch {
        id: openConnectNoHTTPKeepAlive

        //% "Disable HTTP connection re-use"
        text: qsTrId("settings_network-la-vpn_openconnect_no_http_keepalive")
    }

    TextSwitch {
        id: openConnectNoDTLS

        //% "Disable DTLS and ESP"
        text: qsTrId("settings_network-la-vpn_openconnect_no_dtls_and_esp")
    }
}
