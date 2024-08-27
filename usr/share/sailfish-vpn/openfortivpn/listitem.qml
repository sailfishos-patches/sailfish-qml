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

VpnTypeItem {
    canImport: true
    onClicked: {
        pageStack.animatorPush("OfvFileSettingsDialog.qml", { mainPage: _mainPage })
    }

    //% "Fortinet"
    name: qsTrId("settings_network-me-vpn_type_openfortivpn")

    //% "An open implementation of Fortinet's proprietary PPP+SSL VPN solution"
    description: qsTrId("settings_network-la-vpn_type_openfortivpn")
}
