import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Settings.Networking 1.0
import Sailfish.Settings.Networking.Vpn 1.0

VpnPlatformEditDialog {
    id: root

    property string importPath

    title: {
        if (newConnection) {
            if (importPath) {
                //% "OpenVPN set up is ready!"
                return qsTrId("settings_network-he-vpn_import_ovpn_success")
            } else {
                //% "Add new OpenVPN connection"
                return qsTrId("settings_network-he-vpn_add_new_openvpn")
            }
        }
        //% "Edit OpenVPN connection"
        return qsTrId("settings_network-he-vpn_edit_openvpn")
    }

    Binding {
        when: root.newConnection && VpnTypes.ovpnImportPath
        target: root
        property: 'subtitle'

        //% "Settings have been imported. You can change the settings now or later after saving the connection. If username and password are required, they will be requested after turning on the connection."
        value:qsTrId("settings_network-he-vpn_import_openvpn_message")
    }

    vpnType: "openvpn"
    firstAdditionalItem: openVpnCACert

    Component.onCompleted: {
        init()

        if (importPath) {
            // Use the file name as the suggested name for the VPN
            if (!vpnName) {
                var start = importPath.lastIndexOf('/')
                start += 1

                var ciPath = importPath.toLowerCase()
                var end = ciPath.lastIndexOf('.ovpn')
                if (end != -1) {
                    vpnName = importPath.substring(start, end)
                } else {
                    vpnName = importPath.substr(start)
                }
            }
        }

        openVpnCACert.path = getProviderProperty('OpenVPN.CACert')

        var authPath = getProviderProperty('OpenVPN.AuthUserPass')
        if (authPath == '') {
            openVpnAuthUserPass.path = ''
            openVpnAuthProvision.currentIndex = 0
        } else if (authPath == '-') {
            openVpnAuthUserPass.path = ''
            openVpnAuthProvision.currentIndex = 1
        } else {
            openVpnAuthUserPass.path = authPath
            openVpnAuthProvision.currentIndex = 2
        }

    }

    canAccept: {
        if (!validSettings) {
            return false
        }

        if (openVpnAuthProvision.currentIndex === 2 && openVpnAuthUserPass.path.length === 0) {
            return false
        }

        return openVpnCACert.path.length > 0
    }

    onAccepted: {
        updateProvider('OpenVPN.CACert', openVpnCACert.path)
        updateProvider('OpenVPN.AuthUserPass', openVpnAuthUserPass.path)

        if (openVpnAuthProvision.currentIndex == 0) {
            updateProvider('OpenVPN.AuthUserPass', '')
        } else if (openVpnAuthProvision.currentIndex == 1) {
            updateProvider('OpenVPN.AuthUserPass', '-')
        } else if (openVpnAuthProvision.currentIndex == 2) {
            updateProvider('OpenVPN.AuthUserPass', openVpnAuthUserPass.path)
        }

        saveConnection()
    }

    ConfigPathField {
        id: openVpnCACert

        //% "Certificate Authority file"
        label: qsTrId("settings_network-la-vpn_openvpn_cacert")
    }

    ComboBox {
        id: openVpnAuthProvision

        property var values: [
            //% "Not required"
            qsTrId("settings_network-la-vpn_openvpn_auth_not_required"),
            //% "Ask when needed"
            qsTrId("settings_network-la-vpn_openvpn_auth_ask"),
            //% "Read from file"
            qsTrId("settings_network-la-vpn_openvpn_auth_from_file")
        ]

        //% "Authentication credentials"
        label: qsTrId("settings_network-la-vpn_openvpn_auth_provision")
        width: parent.width
        menu: ContextMenu {
            Repeater {
                model: openVpnAuthProvision.values
                delegate: MenuItem { text: modelData }
            }
        }
    }

    ConfigPathField {
        id: openVpnAuthUserPass

        visible: opacity != 0
        opacity: openVpnAuthProvision.currentIndex == 2 ? 1 : 0
        Behavior on opacity { FadeAnimation { duration: 200 } }

        height: visible ? implicitHeight : 0
        Behavior on height { NumberAnimation { duration: 200 } }

        //% "OpenVPN password file"
        label: qsTrId("settings_network-la-vpn_openvpn_authuserpass")
    }
}

