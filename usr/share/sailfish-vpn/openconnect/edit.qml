import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Settings.Networking 1.0
import Sailfish.Settings.Networking.Vpn 1.0

VpnPlatformEditDialog {
                           //% "Add new OpenConnect connection"
    title: newConnection ? qsTrId("settings_network-he-vpn_add_new_openconnect")
                           //% "Edit OpenConnect connection"
                         : qsTrId("settings_network-he-vpn_edit_openconnect")

    vpnType: "openconnect"

    Component.onCompleted: {
        init()
        var authType = getProviderProperty('OpenConnect.AuthType')
        switch (authType) {
        case 'cookie':
            openConnectAuthType.currentIndex = 0
            break
        case 'cookie_with_userpass':
            openConnectAuthType.currentIndex = 1
            break
        case 'userpass':
            openConnectAuthType.currentIndex = 2
            break
        case 'publickey':
            openConnectAuthType.currentIndex = 3
            break
        case 'pkcs':
            openConnectAuthType.currentIndex = 4
            break
        default:
            openConnectAuthType.currentIndex = 2
        }
    }

    canAccept: {
        switch (openConnectAuthType.currentIndex) {
        case 0:
            // Manually set cookie is not mandatory, it is queried with VPN agent
        case 1:
        case 2:
            break
        case 3:
            if (openConnectClientCert.path.length === 0 || openConnectPrivateKey.path.length === 0)
                return false
            break
        case 4:
            if (openConnectPKCS.path.length === 0)
                return false
            break
        }

        return true
    }

    onAccepted: {
        switch (openConnectAuthType.currentIndex) {
        case 0:
            updateProvider('OpenConnect.AuthType', 'cookie')
            updateProvider('OpenConnect.Cookie', openConnectCookie.text)
            break
        case 1:
            updateProvider('OpenConnect.AuthType', 'cookie_with_userpass')
            break
        case 2:
            updateProvider('OpenConnect.AuthType', 'userpass')
            break
        case 3:
            updateProvider('OpenConnect.AuthType', 'publickey')
            updateProvider('OpenConnect.ClientCert', openConnectClientCert.path)
            updateProvider('OpenConnect.UserPrivateKey', openConnectPrivateKey.path)
            break
        case 4:
            updateProvider('OpenConnect.AuthType', 'pkcs')
            updateProvider('OpenConnect.PKCSClientCert', openConnectPKCS.path)
            break
        }

        saveConnection()
    }

    function authTypeDescription(index) {
        switch (index) {
        case 0:
            //% "Input connection cookie manually"
            return qsTrId("settings_network-la-vpn_openconnect_manual_cookie_description")
        case 1:
            //% "Credentials are used to retrieve connection cookie"
            return qsTrId("settings_network-la-vpn_openconnect_automatic_cookie_description")
        case 2:
            //% "Authorize and connect with username and password"
            return qsTrId("settings_network-la-vpn_openconnect_credential_description")
        case 3:
            //% "Authorize with client certificate and private key"
            return qsTrId("settings_network-la-vpn_openconnect_public_key_description")
        case 4:
            //% "Authorize with protected PKCS#1/#8/#12 file"
            return qsTrId("settings_network-la-vpn_openconnect_pkcs_description")
        }
    }

    SectionHeader {
        //% "Authentication"
        text: qsTrId("settings_network-la-vpn_openconnect_credentials")
    }

    ComboBox {
        id: openConnectAuthType

        //% "Method"
        label: qsTrId("settings_network-la-vpn_openconnect_auth_method")
        menu: ContextMenu {
            //% "Manual cookie"
            MenuItem { text: qsTrId("settings_network-la-vpn_openconnect_auth_type_manual_cookie") }
            //% "Automatic cookie"
            MenuItem { text: qsTrId("settings_network-la-vpn_openconnect_auth_type_automatic_cookie") }
            //% "Credentials"
            MenuItem { text: qsTrId("settings_network-la-vpn_openconnect_auth_type_userpass") }
            //% "Public key"
            MenuItem { text: qsTrId("settings_network-la-vpn_openconnect_auth_type_publickey") }
            //% "PKCS#1/#8/#12"
            MenuItem { text: qsTrId("settings_network-la-vpn_openconnect_auth_type_pkcs") }
        }

        description: authTypeDescription(currentIndex)
    }

    ConfigTextField {
        id: openConnectCookie
        visible: openConnectAuthType.currentIndex === 0

        //% "Cookie string"
        label: qsTrId("settings_network-la-vpn_openconnect_cookie")
        text: getProviderProperty('OpenConnect.Cookie')
    }

    ConfigPathField {
        id: openConnectClientCert
        visible: openConnectAuthType.currentIndex === 3

        //% "Certificate file"
        label: qsTrId("settings_network-la-vpn_openconnect_clientcert")
        path: getProviderProperty('OpenConnect.ClientCert')
    }

    ConfigPathField {
        id: openConnectPrivateKey
        visible: openConnectAuthType.currentIndex === 3

        //% "Private key file"
        label: qsTrId("settings_network-la-vpn_openconnect_privatekey")
        path: getProviderProperty('OpenConnect.UserPrivateKey')
    }

    ConfigPathField {
        id: openConnectPKCS
        visible: openConnectAuthType.currentIndex === 4

        //% "PKCS#1/#8/#12 certificate file"
        label: qsTrId("settings_network-la-vpn_openconnect_pkcscert")
        path: getProviderProperty('OpenConnect.PKCSClientCert')
    }
}

