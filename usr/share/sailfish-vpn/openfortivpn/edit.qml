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

VpnPlatformEditDialog {
    //% "Add new openfortivpn connection"
    newTitle: qsTrId("settings_network-he-vpn_add_new_openfortivpn")
    //% "Edit openfortivpn connection"
    editTitle: qsTrId("settings_network-he-vpn_edit_openfortivpn")
    //% "Openfortivpn set up is ready!"
    importTitle: qsTrId("settings_network-he-vpn_import_openfortivpn_success")

    Binding on subtitle {
        when: newConnection && importPath
        //% "Settings have been imported. You can change the settings now or later after saving the connection. If username and password are required, they will be requested after turning on the connection."
        value: qsTrId("settings_network-he-vpn_import_openfortivpn_message")
    }

    vpnType: "openfortivpn"

    onAccepted: saveConnection()
    Component.onCompleted: init()
}
