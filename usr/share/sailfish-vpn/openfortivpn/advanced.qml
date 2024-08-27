/*
 * Copyright (c) 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Settings.Networking 1.0
import Sailfish.Settings.Networking.Vpn 1.0

Column {
    function setProperties(providerProperties) {
        openfortivpnPort.text = getProperty('openfortivpn.Port')
        // This option is for PPPD
        openfortivpnNoIPv6.checked = getProperty('PPPD.NoIPv6') === 'true'
        openfortivpnAllowSelfSignedCert.checked = getProperty('openfortivpn.AllowSelfSignedCert') === 'true'
        openfortivpnTrustedCert.text = getProperty('openfortivpn.TrustedCert')
    }

    function updateProperties(providerProperties) {
        updateProvider('openfortivpn.Port', openfortivpnPort.filteredText)
        updateProvider('PPPD.NoIPv6', openfortivpnNoIPv6.checked.toString())
        updateProvider('openfortivpn.AllowSelfSignedCert', openfortivpnAllowSelfSignedCert.checked ? 'true' : 'false')
        updateProvider('openfortivpn.TrustedCert', openfortivpnTrustedCert.text)
    }

    width: parent.width

    SectionHeader {
        //: Settings pertaining to the communication channel
        //% "Communications"
        text: qsTrId("settings_network-he-vpn_openfortivpn_communications")
    }

    ConfigIntField {
        id: openfortivpnPort
        intUpperLimit: 65535

        //% "Port"
        label: qsTrId("settings_network-la-vpn_openfortivpn_port")
        //% "Port number must be a value between 1 and 65535"
        description: errorHighlight ? qsTrId("settings_network_la-vpn_openfortivpn_port_error") : ""

        nextFocusItem: openfortivpnTrustedCert
    }

    TextSwitch {
        id: openfortivpnNoIPv6

        //% "Disable IPv6 (enables IPv6 data leak protection)"
        text: qsTrId("settings_network-la-vpn_pppd_noipv6")
    }

    SectionHeader {
        //% "Server"
        text: qsTrId("settings_network-la-vpn_openfortivpn_server")
    }

    TextSwitch {
        id: openfortivpnAllowSelfSignedCert

        //% "Allow self signed certificate"
        text: qsTrId("settings_network-la-vpn_openfortivpn_allow_self_signed_certificate")
    }

    ConfigTextField {
        id: openfortivpnTrustedCert

        //% "Trusted certificate fingerprint"
        label: qsTrId("settings_network-la-vpn_openfortivpn_trusted_cert_fingerprint")
    }
}
