/****************************************************************************
**
** Copyright (C) 2019 Jolla Ltd.
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Settings.Networking 1.0
import MeeGo.Connman 0.2
import Nemo.DBus 2.0

Column {
    id: root
    width: parent.width

    property var formData: ({})
    property alias servicePath: service.path
    property bool canAccept: identityField.text !== '' && passphraseField.text !== ''

    signal enterKeyClicked
    signal closeDialog

    function focus() {
        if (ssidField.visible)
            ssidField.forceActiveFocus()
        else
            identityField.forceActiveFocus()
    }

    function result() {
        return network.json()
    }

    NetworkService {
        id: service
    }

    NetworkConfig {
        id: network
        securityType: service ? service.securityType : NetworkService.SecurityIEEE802
        ssid: service ? service.name : ''
        hidden: service && !service.name
    }

    AddNetworkHelper {
        id: networkHelper
    }

    SsidField {
        id: ssidField
        network: network
        visible: network.hidden

        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: identityField.focus = true
    }

    EapComboBox {
        network: network
    }

    InnerAuthComboBox {
        network: network
    }

    DBusInterface {
        id: settingsDBus
        service: "com.jolla.settings"
        path: "/com/jolla/settings/ui"
        iface: "com.jolla.settings.ui"
    }

    CACertChooser {
        network: network

        onFromFileSelected: {
            networkHelper.writeSettings(
                        {
                            "ssid": network.ssid,
                            "securityType": network.securityType,
                            "eapMethod": network.eapMethod,
                            "phase2": network.phase2,
                            "identity": network.identity,
                            "passphrase": network.passphrase,
                            "caCert": "custom",
                            "privateKeyFile": network.privateKeyFile,
                            "clientCertFile": network.clientCertFile,
                            "hidden": network.hidden
                        })
            settingsDBus.call("showAddNetworkDialog");
            root.closeDialog()
        }
    }

    ClientCertChooser {
        network: network

        onKeyFromFileSelected: {
            networkHelper.writeSettings(
                        {
                            "ssid": network.ssid,
                            "securityType": network.securityType,
                            "eapMethod": network.eapMethod,
                            "phase2": network.phase2,
                            "identity": network.identity,
                            "passphrase": network.passphrase,
                            "caCert": network.caCert,
                            "privateKeyFile": "custom",
                            "clientCertFile": network.clientCertFile,
                            "hidden": network.hidden
                        })
            settingsDBus.call("showAddNetworkDialog");
            root.closeDialog()
        }

        onCertFromFileSelected: {
            networkHelper.writeSettings(
                        {
                            "ssid": network.ssid,
                            "securityType": network.securityType,
                            "eapMethod": network.eapMethod,
                            "phase2": network.phase2,
                            "identity": network.identity,
                            "passphrase": network.passphrase,
                            "caCert": network.caCert,
                            "caCertFile": network.caCertFile,
                            "privateKeyFile": network.privateKeyFile,
                            "clientCertFile": "custom",
                            "hidden": network.hidden
                        })
            settingsDBus.call("showAddNetworkDialog");
            root.closeDialog()
        }
    }

    IdentityField {
        id: identityField

        network: network
        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: passphraseField.focus = true
    }

    PassphraseField {
        id: passphraseField

        network: network
        immediateUpdate: true
        EnterKey.enabled: root.canAccept
        EnterKey.iconSource: "image://theme/icon-m-enter-accept"
        EnterKey.onClicked: root.enterKeyClicked()
    }
}
