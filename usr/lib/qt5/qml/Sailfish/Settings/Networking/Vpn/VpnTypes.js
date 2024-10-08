/*
 * Copyright (c) 2018 - 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

.pragma library
.import org.nemomobile.systemsettings 1.0 as SystemSettings
.import Sailfish.Silica 1.0 as Silica
.import Connman 0.2 as Connman

var settingsPath = "/usr/share/sailfish-vpn/"

function detailsPagePath(vpnType) {
    return settingsPath + vpnType + "/details.qml"
}

function editDialogPath(vpnType) {
    return settingsPath + vpnType + "/edit.qml"
}

function importPath(vpnType) {
    return settingsPath + vpnType + "/import.qml"
}

function importDialogPath(vpnType) {
    return settingsPath + vpnType + "/importdialog.qml"
}

function advancedSettingsPath(vpnType) {
    return settingsPath + vpnType + "/advanced.qml"
}

function stateName(state) {
    switch (state) {
    case Connman.VpnConnection.Idle:
        //% "Idle"
        return qsTrId("settings_network-me-vpn_state_idle")
    case Connman.VpnConnection.Failure:
        //% "Failure"
        return qsTrId("settings_network-me-vpn_state_failure")
    case Connman.VpnConnection.Association:
        //: Shown during the time the system is waiting for user to input credentials.
        //% "Association"
        return qsTrId("settings_network-me-vpn_state_association")
    case Connman.VpnConnection.Configuration:
        //% "Configuration"
        return qsTrId("settings_network-me-vpn_state_configuration")
    case Connman.VpnConnection.Ready:
        //% "Ready"
        return qsTrId("settings_network-me-vpn_state_ready")
    case Connman.VpnConnection.Disconnect:
        //% "Disconnect"
        return qsTrId("settings_network-me-vpn_state_disconnect")
    default:
        console.log("Warning: Unknown VPN connection state")
    }
}

function presentationName(input) {
    switch (input) {

    case "psk":
        //: Acronym for: pre-shared key
        //% "PSK"
        return qsTrId("settings_network-me-presentation_psk")
    case "dh1":
        //: Acronym for: Diffie-Hellman group 1
        //% "DH1"
        return qsTrId("settings_network-me-presentation_dh1")
    case "dh2":
        //: Acronym for: Diffie-Hellman group 2
        //% "DH2"
        return qsTrId("settings_network-me-presentation_dh2")
    case "dh5":
        //: Acronym for: Diffie-Hellman group 5
        //% "DH5"
        return qsTrId("settings_network-me-presentation_dh5")
    case "cisco":
        //: Company name for Cisco Systems Inc.
        //% "Cisco"
        return qsTrId("settings_network-me-presentation_cisco")
    case "netscreen":
        //: Company name for NetScreen Technologies
        //% "NetScreen"
        return qsTrId("settings_network-me-presentation_netscreen")
    case "natt":
        //: Acronym for: network address translation traversal
        //% "NAT-T"
        return qsTrId("settings_network-me-presentation_natt")
    case "cisco-udp":
        //: Acronym for: user datagram protocol as employed by Cisco VPN implementation
        //% "Cisco UDP"
        return qsTrId("settings_network-me-presentation_cisco_udp")
    case "tun":
        //: Presentation form indicating a network tunnel device
        //% "TUN"
        return qsTrId("settings_network-me-presentation_tun")
    case "tap":
        //: Presentation form indicating a network tap device
        //% "TAP"
        return qsTrId("settings_network-me-presentation_tap")
    case "udp":
        //: Acronym for: user datagram protocol
        //% "UDP"
        return qsTrId("settings_network-me-presentation_udp")
    case "tcp":
    case "tcp-client":
        //: Acronym for: transmission control protocol
        //% "TCP"
        return qsTrId("settings_network-me-presentation_tcp")
    case "_default":
        //: Indicator for default selection; user has not specified a value
        //% "Default"
        return qsTrId("settings_network-me-vpn_default_option")
    case "true":
    case "yes":
        //% "Yes"
        return qsTrId("settings_network-me-vpn_presentation_yes")
    case "false":
    case "no":
        //% "No"
        return qsTrId("settings_network-me-vpn_presentation_no")
    case "adaptive":
        //% "Adaptive"
        return qsTrId("settings_network-me-vpn_presentation_adaptive")
    case "none":
        //% "None"
        return qsTrId("settings_network-me-vpn_presentation_none")
    case "server":
        //% "Server"
        return qsTrId("settings_network-me-vpn_presentation_server")
    case "client":
        //% "Client"
        return qsTrId("settings_network-me-vpn_presentation_client")
    case "cert":
        //% "Certificate"
        return qsTrId("settings_network-me-vpn_presentation_cert")
    case "hybrid":
        //% "Hybrid"
        return qsTrId("settings_network-me-vpn_presentation_hybrid")
    case "nopfs":
        //% "None"
        return qsTrId("settings_network-me-vpn_presentation_nopfs")
    case "force-natt":
        //: Enforce the application of NAT-T
        //% "Enforce NAT-T"
        return qsTrId("settings_network-me-presentation_force_natt")
    case "no-mppe":
        //% "Not required"
        return qsTrId("settings_network-me-vpn_mppe_not_required")
    case "mppe-required":
        //% "Required"
        return qsTrId("settings_network-me-vpn_mppe_required")
    case "mppe40-required":
        //% "40-bit required"
        return qsTrId("settings_network-me-vpn_mppe_required_40bit")
    case "mppe128-required":
        //% "128-bit required"
        return qsTrId("settings_network-me-vpn_mppe_required_128bit")
    case "no-auth":
        //% "Not required"
        return qsTrId("settings_network-me-vpn_auth_not_required")
    case "auth-required":
        //% "Required"
        return qsTrId("settings_network-me-vpn_auth_required")
    case "auth-pap-required":
        //% "PAP required"
        return qsTrId("settings_network-me-vpn_auth_required_pap")
    case "auth-chap-required":
        //% "CHAP required"
        return qsTrId("settings_network-me-vpn_auth_required_chap")
    case "SIGHUP":
        //% "SIGHUP"
        return qsTrId("settings_network_me-vpn_signal_hup")
    case "SIGTERM":
        //% "SIGTERM"
        return qsTrId("settings_network_me-vpn_signal_term")
    default:
        console.log("Warning: No translation found for attribute", input)
    }
    return ""
}

function importFile(pageStack, mainPage, path, vpnType, parser) {
    var props = parser(path)
    if (Object.keys(props).length == 0) {
        var failureDialog = importDialogPath(vpnType)
        if (pageStack.currentPage != mainPage) {
            pageStack.animatorReplaceAbove(mainPage, failureDialog, { _mainPage: mainPage, _vpnType: vpnType, importFailed: true })
        } else {
            pageStack.push(failureDialog, { _mainPage: mainPage }, Silica.PageStackAction.Immediate)
        }
    } else {
        var connectionProperties = {}
        var providerProperties = {}

        for (var name in props) {
            if (name == 'Host' || name == 'Name') {
                connectionProperties[name.toLowerCase()] = props[name]
            } else {
                providerProperties[name] = props[name]
            }
        }

        props = {
            newConnection: true,
            importPath: path,
            vpnType: vpnType,
            connectionProperties: connectionProperties,
            providerProperties: providerProperties
        }

        if (pageStack.currentPage != mainPage) {
            if (mainPage) {
                props['acceptDestination'] = mainPage
            }
            pageStack.animatorReplaceAbove(mainPage, editDialogPath(props.vpnType), props)
        } else {
            pageStack.push(editDialogPath(props.vpnType), props, Silica.PageStackAction.Immediate)
        }
    }
}
