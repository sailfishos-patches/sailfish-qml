/*
 * Copyright (c) 2018 - 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import MeeGo.Connman 0.2
import Nemo.DBus 2.0
import com.jolla.settings 1.0
import org.nemomobile.systemsettings 1.0

SettingsToggle {
    id: root

    property string _connectionName
    readonly property bool waitForConnection: (!networkManager.connected || (SettingsVpnModel.bestState <= VpnConnection.Configuration)) && SettingsVpnModel.autoConnect

    function _updateConnectionName() {
        var connectionName = ""
        for (var i = 0; i < SettingsVpnModel.count; ++i) {
            var conn = SettingsVpnModel.get(i)
            if (conn.state == VpnConnection.Ready) {
                connectionName = conn.name
                break
            }
        }
        _connectionName = connectionName
    }

    //% "VPN"
    name: qsTrId("settings_networking-vpn")
    activeText: _connectionName
    icon.source: "image://theme/icon-m-vpn"

    active: SettingsVpnModel.bestState == VpnConnection.Ready
    checked: (SettingsVpnModel.bestState != VpnConnection.Idle
             && SettingsVpnModel.bestState != VpnConnection.Failure) || waitForConnection

    busy: (SettingsVpnModel.bestState == VpnConnection.Configuration || SettingsVpnModel.bestState == VpnConnection.Disconnect)
          && !waitForConnection

    menu: ContextMenu {
        SettingsMenuItem {
            onClicked: root.goToSettings()
        }

        MenuItem {
            //% "Add new VPN"
            text: qsTrId("settings_network-me-vpn_add_new_vpn")
            visible: SettingsVpnModel.count == 0
            onClicked: jollaSettings.call("newVpnConnection")
        }
    }

    onToggled: {
        if (checked) {
            for (var i = 0; i < SettingsVpnModel.count; ++i) {
                var conn = SettingsVpnModel.get(i)
                conn.autoConnect = false
                if (conn.state === VpnConnection.Ready) {
                    SettingsVpnModel.deactivateConnection(conn.path)
                }
            }
        } else if (SettingsVpnModel.count === 1) {
            SettingsVpnModel.get(0).autoConnect = true
        } else {
            // Open settings page so user can choose a VPN connection
            goToSettings("system_settings/connectivity/vpn")
        }
    }

    Component.onCompleted: _updateConnectionName()

    Connections {
        target: SettingsVpnModel
        onConnectionStateChanged: _updateConnectionName()
    }

    DBusInterface {
        id: jollaSettings

        service: "com.jolla.settings"
        path: "/com/jolla/settings/ui"
        iface: "com.jolla.settings.ui"
    }

    NetworkManager {
        id: networkManager
    }
}
