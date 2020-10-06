import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import Sailfish.Settings.Networking 1.0
import MeeGo.Connman 0.2

Dialog {
    id: root

    readonly property var _focusItems: [
        ssidField,
        caCertChooser.domainField,
        clientCertChooser.passphraseField,
        identityField,
        passphraseField,
        anonymousIdentityField,
        advancedSettingsColumn.firstFocusableItem,
        column
    ]

    property NetworkManager networkManager
    canAccept: network.ssid.length > 0 &&
               (!passphraseField.required || network.passphrase.length > 0) &&
               (!identityField.required   || (network.identity.length > 3 && network.identity.length <= 63)) &&
               clientCertChooser.canAccept

    function _nextFocus(from) {
        var i = _focusItems.indexOf(from)
        if (i === -1)
            return null
        for (i++; i < _focusItems.length; i++)
            if (_focusItems[i] && _focusItems[i].visible)
                return _focusItems[i]
        return null
    }

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

    onStatusChanged: if (status == PageStatus.Active) {
        caCertChooser.cancel()
        clientCertChooser.cancel()
    }

    Connections {
        target: network

        onCaCertChanged: {
            if (network.caCert === 'custom' && status === PageStatus.Active) {
                caCertChooser.fromFileSelected()
                network.caCert = ''
            }
        }
        onClientCertFileChanged: {
            if (network.clientCertFile === 'custom' && status === PageStatus.Active) {
                clientCertChooser.certFromFileSelected()
                network.clientCertFile = ''
            }
        }
        onPrivateKeyFileChanged: {
            if (network.privateKeyFile === 'custom' && status === PageStatus.Active) {
                clientCertChooser.keyFromFileSelected()
                network.privateKeyFile = ''
            }
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

                property Item nextFocusItem: _nextFocus(this)
                EnterKey.iconSource: nextFocusItem !== parent ? "image://theme/icon-m-enter-next"
                                               : "image://theme/icon-m-enter-close"
                EnterKey.onClicked: if (nextFocusItem) nextFocusItem.focus = true
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

                onFromFileSelected: pageStack.push(fileLoaderPage, { fieldName: 'caCert' })
                immediateUpdate: true

                property Item nextFocusItem: _nextFocus(this.domainField)
                EnterKey.iconSource: nextFocusItem !== parent ? "image://theme/icon-m-enter-next"
                                               : "image://theme/icon-m-enter-close"
                EnterKey.onClicked: if (nextFocusItem) nextFocusItem.focus = true
            }

            ClientCertChooser {
                id: clientCertChooser
                network: root.network
                immediateUpdate: true

                onKeyFromFileSelected: pageStack.push(filePickerPage, { fieldName: 'privateKeyFile', nameFilters: ['*.pem', '*.key', '*.p12', '*.pfx'] })
                onCertFromFileSelected: pageStack.push(filePickerPage, { fieldName: 'clientCertFile', nameFilters: ['*.pem', '*.crt'] })

                property Item nextFocusItem: _nextFocus(this.passphraseField)
                EnterKey.iconSource: nextFocusItem !== parent ? "image://theme/icon-m-enter-next"
                                               : "image://theme/icon-m-enter-close"
                EnterKey.onClicked: if (nextFocusItem) nextFocusItem.focus = true
            }

            IdentityField {
                id: identityField

                network: root.network
                immediateUpdate: true

                property Item nextFocusItem: _nextFocus(this)
                EnterKey.iconSource: nextFocusItem !== parent ? "image://theme/icon-m-enter-next"
                                               : "image://theme/icon-m-enter-close"
                EnterKey.onClicked: if (nextFocusItem) nextFocusItem.focus = true
            }

            PassphraseField {
                id: passphraseField

                network: root.network
                immediateUpdate: true

                property Item nextFocusItem: _nextFocus(this)
                EnterKey.iconSource: nextFocusItem !== parent ? "image://theme/icon-m-enter-next"
                                               : "image://theme/icon-m-enter-close"
                EnterKey.onClicked: if (nextFocusItem) nextFocusItem.focus = true
            }

            AnonymousIdentityField {
                id: anonymousIdentityField

                network: root.network
                immediateUpdate: true

                property Item nextFocusItem: _nextFocus(this)
                EnterKey.iconSource: nextFocusItem !== parent ? "image://theme/icon-m-enter-next"
                                               : "image://theme/icon-m-enter-close"
                EnterKey.onClicked: if (nextFocusItem) nextFocusItem.focus = true
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
        id: fileLoaderPage

        FilePickerPage {
            nameFilters: [ '*.crt', '*.pem' ]
            property string fieldName
            onSelectedContentPropertiesChanged: network[fieldName] = CertHelper.readCert(selectedContentProperties.filePath, 'CERTIFICATE')
        }
    }

    Component {
        id: filePickerPage

        FilePickerPage {
            nameFilters: [ '*.crt', '*.pem' ]
            property string fieldName
            onSelectedContentPropertiesChanged: network[fieldName] = selectedContentProperties.filePath
        }
    }
}
