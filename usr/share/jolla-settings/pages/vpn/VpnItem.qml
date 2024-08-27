/*
 * Copyright (c) 2018 - 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Connman 0.2
import Sailfish.Policy 1.0
import Nemo.Connectivity 1.0
import Sailfish.Settings.Networking.Vpn 1.0

ListItem {
    id: root

    property QtObject connection

    property bool networkOnline
    readonly property bool connected: connection ? (connection.state === VpnConnection.Ready) : false
    readonly property bool connectionAccess: AccessPolicy.vpnConnectionSettingsEnabled
    readonly property bool configurationAccess: AccessPolicy.vpnConfigurationSettingsEnabled

    function remove() {
        //% "Forgotten"
        remorseAction(qsTrId("settings_network-la-forgotten"),
                      function() { SettingsVpnModel.deleteConnection(connection.path) })
    }
    ListView.onRemove: animateRemoval()

    contentHeight: textSwitch.height
    highlighted: textSwitch.down || textNoSwitch.down || menuOpen || (connected && !textNoSwitch.visible)
    _backgroundColor: "transparent"

    openMenuOnPressAndHold: false
    menu: Component {
        ContextMenu {
            MenuItem {
                //% "Edit"
                text: qsTrId("settings_network-me-edit")
                visible: !connection.immutable && connectionAccess & configurationAccess
                onClicked: {
                    var properties = {
                        //% "Edit VPN settings"
                        title: qsTrId("settings_network-he-vpn_edit_vpn_settings"),
                        newConnection: false,
                        connection: SettingsVpnModel.connectionSettings(connection.path),
                        acceptDestination: pageStack.currentPage
                    }
                    pageStack.animatorPush(VpnTypes.editDialogPath(connection.type), properties)
                }
            }
            MenuItem {
                //% "Forget"
                text: qsTrId("settings_network-me-forget")
                visible: connectionAccess && configurationAccess
                onClicked: root.remove()
            }
            MenuItem {
                //% "Details"
                text: qsTrId("settings_network-me-connection_details")
                onClicked: {
                    pageStack.animatorPush(VpnTypes.detailsPagePath(connection.type), { connection: SettingsVpnModel.connectionSettings(connection.path) })
                }
            }
        }
    }

    Connections {
        target: connection
        onAutoConnectChanged: {
            if (!connection.autoConnect) {
                SettingsVpnModel.deactivateConnection(connection.path)
            }
        }

    }

    TextSwitch {
        id: textSwitch

        visible: !textNoSwitch.visible
        automaticCheck: false
        checked: connection ? connection.autoConnect : false
        highlighted: root.highlighted
        busy: connection ? (connection.state === VpnConnection.Configuration || connection.state === VpnConnection.Association || connection.state === VpnConnection.Disconnect) : false
        text: connection ? connection.name : ''
        description: {
            var state
            if (connection) {
                if (connection.state == VpnConnection.Ready) {
                    //: The VPN is currently connected
                    //% "Connected"
                    state = qsTrId("settings_network-la-connected_state")
                } else if (connection.state == VpnConnection.Failure) {
                    //% "Connection failed"
                    state = qsTrId("settings_network-la-vpn_connection_failure")
                } else if (connection.state == VpnConnection.Disconnect) {
                    //% "Disconnecting..."
                    state = qsTrId("settings_network-la-disconnecting_state")
                } else if (connection.state == VpnConnection.Configuration || connection.state == VpnConnection.Association) {
                    //% "Connecting..."
                    state = qsTrId("settings_network-la-connecting_state")
                } else if (checked && !root.networkOnline) {
                    //% "Waiting for network..."
                    state = qsTrId("settings_network-la-waiting_for_network")
                }
            }

            if (!state) {
                //: The VPN is currently disconnected
                //% "Idle"
                state = qsTrId("settings_network-la-idle_state")
            }
            return state
        }

        onPressAndHold: root.openMenu()
        onClicked: {
            connection.autoConnect = !connection.autoConnect
        }
    }

    TextNoSwitch {
        id: textNoSwitch

        visibleIntent: !connectionAccess
        highlighted: root.highlighted
        text: textSwitch.text
        description: textSwitch.description

        onPressAndHold: root.openMenu()
        onClicked: pageStack.animatorPush(VpnTypes.detailsPagePath(connection.type), { connection: SettingsVpnModel.connectionSettings(connection.path) })
    }
}
