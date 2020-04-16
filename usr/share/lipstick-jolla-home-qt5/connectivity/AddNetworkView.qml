import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import Sailfish.Settings.Networking 1.0
import MeeGo.Connman 0.2
import Nemo.DBus 2.0

Column {
    id: root

    property string path
    property bool canAccept: network.ssid.length > 0 &&
                             (!passphraseField.required || network.passphrase.length > 0) &&
                             (!identityField.required   || network.identity.length > 0)

    signal accepted(var config)
    signal rejected
    signal closeDialog

    function accept() {
        root.forceActiveFocus() // proxy and ipv4 fields update on focus lost
        accepted(network.json())
    }

    width: parent.width

    property QtObject network: NetworkConfig {
        passphraseRequired: passphraseField.required
        identityRequired: identityField.required
    }
    property alias __silica_applicationwindow_instance: fakeApplicationWindow

    Item {
        id: fakeApplicationWindow
        // suppresses warnings by context menu
        property int _dimScreen
    }

    AddNetworkHelper {
        id: networkHelper
    }

    DBusInterface {
        id: settingsDBus
        service: "com.jolla.settings"
        path: "/com/jolla/settings/ui"
        iface: "com.jolla.settings.ui"
    }

    SystemDialogHeader {
        //% "Add network"
        title: qsTrId("lipstick_jolla_home-he-add_network")
        topPadding: Screen.sizeCategory >= Screen.Large ? 2*Theme.paddingLarge : Theme.paddingLarge // align with ConnectionSelector
    }

    SsidField {
        id: ssidField

        network: root.network

        property bool moveFocus: identityField.required || passphraseField.required
        EnterKey.iconSource: moveFocus ? "image://theme/icon-m-enter-next"
                                       : "image://theme/icon-m-enter-close"
        EnterKey.onClicked: {
            if (moveFocus) {
                if (identityField.required) {
                    identityField.focus = true
                } else if (passphraseField.required) {
                    passphraseField.focus = true
                }
            } else {
                focus = false
            }
        }
    }

    HiddenSwitch {
        network: root.network
    }

    EncryptionComboBox {
        network: root.network
    }

    Item {
        width: 1
        height: Theme.paddingMedium
        visible: network.securityType === NetworkService.SecurityNone
    }

    EapComboBox {
        network: root.network
    }

    InnerAuthComboBox {
        network: root.network
    }

    CACertChooser {
        network: root.network

        onFromFileSelected: {
            networkHelper.writeSettings(
                        {
                            "ssid": root.network.ssid,
                            "securityType": root.network.securityType,
                            "eapMethod": root.network.eapMethod,
                            "phase2": root.network.phase2,
                            "identity": root.network.identity,
                            "passphrase": root.network.passphrase,
                            "caCert": "custom",
                            "privateKeyFile": root.network.privateKeyFile,
                            "clientCertFile": root.network.clientCertFile,
                            "hidden": root.network.hidden
                        })
            settingsDBus.call("showAddNetworkDialog");
            root.closeDialog()
        }
    }

    ClientCertChooser {
        network: root.network

        onKeyFromFileSelected: {
            networkHelper.writeSettings(
                        {
                            "ssid": root.network.ssid,
                            "securityType": root.network.securityType,
                            "eapMethod": root.network.eapMethod,
                            "phase2": root.network.phase2,
                            "identity": root.network.identity,
                            "passphrase": root.network.passphrase,
                            "caCert": root.network.caCert,
                            "caCertFile": root.network.caCertFile,
                            "privateKeyFile": "custom",
                            "clientCertFile": root.network.clientCertFile,
                            "hidden": root.network.hidden
                        })
            settingsDBus.call("showAddNetworkDialog");
            root.closeDialog()
        }
        onCertFromFileSelected: {
            networkHelper.writeSettings(
                        {
                            "ssid": root.network.ssid,
                            "securityType": root.network.securityType,
                            "eapMethod": root.network.eapMethod,
                            "phase2": root.network.phase2,
                            "identity": root.network.identity,
                            "passphrase": root.network.passphrase,
                            "caCert": root.network.caCert,
                            "caCertFile": root.network.caCertFile,
                            "privateKeyFile": root.network.privateKeyFile,
                            "clientCertFile": "custom",
                            "hidden": root.network.hidden
                        })
            settingsDBus.call("showAddNetworkDialog");
            root.closeDialog()
        }
    }

    IdentityField {
        id: identityField

        network: root.network

        immediateUpdate: true
        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: passphraseField.focus = true
    }

    PassphraseField {
        id: passphraseField

        network: root.network
        immediateUpdate: true
        EnterKey.enabled: root.canAccept
        EnterKey.iconSource: "image://theme/icon-m-enter-accept"
        EnterKey.onClicked: root.accept()
    }

    Button {
        //% "Advanced"
        text: qsTrId("lipstick_jolla_home-bt-advanced")
        anchors.horizontalCenter: parent.horizontalCenter
        onClicked: {
            networkHelper.writeSettings(
                        {
                            "ssid": root.network.ssid,
                            "securityType": root.network.securityType,
                            "eapMethod": root.network.eapMethod,
                            "phase2": root.network.phase2,
                            "identity": root.network.identity,
                            "passphrase": root.network.passphrase,
                            "caCertFile": root.network.caCertFile,
                            "domainSuffixMatch": root.network.domainSuffixMatch,
                            "hidden": root.network.hidden
                        })
            settingsDBus.call("showAddNetworkDialog")
            root.closeDialog()
        }
    }

    Item {
        width: 1; height: Theme.paddingMedium
    }

    Row {
        width: parent.width
        height: Math.max(cancelButton.implicitHeight, saveButton.implicitHeight)

        SystemDialogTextButton {
            id: cancelButton
            width: parent.width / 2
            height: parent.height
            //% "Cancel"
            text: qsTrId("lipstick-jolla-home-bt-cancel")
            bottomPadding: topPadding
            onClicked: root.rejected()
        }
        SystemDialogTextButton {
            id: saveButton
            enabled: root.canAccept
            width: parent.width / 2
            height: parent.height
            //% "Save"
            text: qsTrId("lipstick-jolla-home-bt-save")
            bottomPadding: topPadding
            onClicked: root.accept()
        }
    }
}
