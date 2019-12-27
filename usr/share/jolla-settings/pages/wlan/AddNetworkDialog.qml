import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import Sailfish.Settings.Networking 1.0
import MeeGo.Connman 0.2

Dialog {
    id: root

    property NetworkManager networkManager
    canAccept: network.ssid.length > 0 &&
               (!passphraseField.required || network.passphrase.length > 0) &&
               (!identityField.required   || network.identity.length > 0)

    function setup(ssid, securityType, identity, passphrase) {
        network.ssid = ssid
        network.securityType = securityType
        network.identity = identity
        network.passphrase = passphrase
    }

    property string path
    onAccepted: {
        root.forceActiveFocus() // proxy and ipv4 fields update on focus lost
        path = networkManager.createServiceSync(network.json())
    }

    property QtObject network: NetworkConfig {
        passphraseRequired: passphraseField.required
        identityRequired: identityField.required
    }

    onStatusChanged: if (status == PageStatus.Active && network.caCert === 'custom') network.caCert = ''

    Connections {
        target: network

        onCaCertChanged: {
            if (network.caCert === 'custom' && status === PageStatus.Active)
                caCertChooser.fromFileSelected()
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge
        Column {
            id: column

            width: parent.width
            DialogHeader {
                dialog: root
                //% "Add network"
                title: qsTrId("settings_network-he-add_network")
                //% "Save"
                acceptText: qsTrId("settings_network-he-save")
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

            EapComboBox {
                network: root.network
            }

            PeapComboBox {
                network: root.network
            }

            InnerAuthComboBox {
                network: root.network
            }

            CACertChooser {
                id: caCertChooser
                network: root.network

                onFromFileSelected: pageStack.push(filePickerPage)
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

                EnterKey.iconSource: "image://theme/icon-m-enter-" + (advancedSettingsColumn.focusable ? "next" : "close")
                EnterKey.onClicked: {
                    if (advancedSettingsColumn.focusable) {
                        advancedSettingsColumn.firstFocusableItem.focus = true
                    } else {
                        parent.focus = true
                    }
                }
            }

            AdvancedSettingsColumn {
                id: advancedSettingsColumn
                network: root.network
                globalProxyButtonVisible: false
            }
        }

        VerticalScrollDecorator {}
    }

    Component {
        id: filePickerPage

        FilePickerPage {
            nameFilters: [ '*.crt', '*.pem' ]
            onSelectedContentPropertiesChanged:
                network.caCert = CertHelper.readCert(selectedContentProperties.filePath)
        }
    }
}
