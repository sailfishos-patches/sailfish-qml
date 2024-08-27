/*
 * Copyright (c) 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */


import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Settings.Networking.Vpn 1.0
import Sailfish.Settings.Networking 1.0

VpnPlatformDetailsPage {
    // The VPN plugin for Fortinet VPN is called a OpenFortiVPN, so the VPN name should be used here.
    //% "Fortinet"
    subtitle: qsTrId("settings_network-me-vpn_type_openfortivpn")
}
