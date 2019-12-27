/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import MeeGo.Connman 0.2
import com.jolla.settings.system 1.0
import Sailfish.Settings.Networking.Vpn 1.0
import org.nemomobile.systemsettings 1.0

Page {
    id: root

    property string importPath
    readonly property bool connectionAccess: AccessPolicy.vpnConnectionSettingsEnabled
    readonly property bool configurationAccess: AccessPolicy.vpnConfigurationSettingsEnabled
    property bool showConnection: !connectionAccess

    onStatusChanged: {
        if (status === PageStatus.Active) {
            if (importPath) {
                if (importPath.indexOf('file://') == 0) {
                    importPath = importPath.substr(7)
                }

                VpnTypes.importOvpnFile(pageStack, root, importPath)
                importPath = ''
            }
        }
    }

    AboutSettings {
        id: aboutSettings
    }

    Binding {
        target: SettingsVpnModel
        property: "orderByConnected"
        value: !connectionAccess
    }

    onConnectionAccessChanged: {
        if (connectionAccess) {
            showConnection = configurationAccess
        }
    }

    onConfigurationAccessChanged: {
        if (!configurationAccess && connectionAccess) {
            showConnection = false
        }
    }

    SilicaListView {
        id: listView

        anchors.fill: parent

        header: Column {
            width: parent.width

            PageHeader {
                //: VPN setting page header
                //% "VPN"
                title: qsTrId("settings_network-he-vpn")
            }

            DisabledByMdmBanner {
                id: disabledByMdmBanner
                active: !connectionAccess || !configurationAccess
                // State used to override properties temporarily
                states: [
                    State {
                        when: connectionAccess && !showConnection
                        name: "configuration"
                        PropertyChanges {
                            target: disabledByMdmBanner
                            //: Shown to explain the kind of MDM policy restricting VPN modification
                            //: as an alternative to "Disabled by %1 Device Manager"
                            //: %1 is an operating system name without the OS suffix
                            //% "Creation, modification, and removal of connections disabled by %1 Device Manager"
                            text: qsTrId("settings_network-la-vpn_modify_mdm_disabled")
                                .arg(aboutSettings.baseOperatingSystemName)
                        }
                    }
                ]
                property real previousHeight: height
                onHeightChanged: {
                    listView.contentY += previousHeight - height
                    previousHeight = height
                }
            }
        }

        model: SettingsVpnModel.populated ? SettingsVpnModel : null

        delegate: VpnItem {
            width: parent.width
            connection: model.vpnService
            networkOnline: networkManager.connected
        }

        section.property: connectionAccess ? "" : "connected"
        section.criteria: ViewSection.FullString
        section.delegate: SectionHeader {
            text: section === "true" ?
                      //: Header shown above a list of the VPNs currently connected
                      //% "Connected"
                      qsTrId("settings_network-sh-vpn_connected") :
                      //: Header shown above a list of the VPNs not currently connected
                      //% "Not connected"
                      qsTrId("settings_network-sh-vpn_not_connected")
        }

        PullDownMenu {
            visible: connectionAccess && configurationAccess
            MenuItem {
                //% "Add new VPN"
                text: qsTrId("settings_network-me-vpn_add_new_vpn")
                onClicked: pageStack.animatorPush('NewConnectionDialog.qml', { mainPage: root })
            }
        }

        ViewPlaceholder {
            //% "There are no VPN connections set up."
            text: qsTrId("settings_network-ph-vpn_add_text")
            //% "Pull down to add a new VPN"
            hintText: connectionAccess && configurationAccess ? qsTrId("settings_network-ph-vpn_add_hint") : ""
            enabled: opacity > 0.0
            opacity: SettingsVpnModel.populated && SettingsVpnModel.count == 0 ? 1 : 0
            Behavior on opacity { FadeAnimation {} }
        }

        VerticalScrollDecorator {}

        NetworkManager {
            id: networkManager
        }
    }
}
