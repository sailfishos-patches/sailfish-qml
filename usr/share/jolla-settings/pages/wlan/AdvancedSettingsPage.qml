import QtQuick 2.0
import Sailfish.Silica 1.0
import MeeGo.Connman 0.2
import Sailfish.Pickers 1.0
import Sailfish.Settings.Networking 1.0

Page {
    id: root

    property QtObject network

    onStatusChanged: if (status == PageStatus.Active) caCertChooser.cancel()

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem {
                //% "Details"
                text: qsTrId("settings_network-me-details")
                onClicked: pageStack.animatorPush("NetworkDetailsPage.qml", {network: network})

            }
            MenuItem {
                //% "Forget network"
                text: qsTrId("settings_network-me-forget_network")
                enabled: root.network
                onClicked: {
                    var network = root.network
                    pageStack.pop()
                    network.remove()
                    root.network = null
                }
            }
        }

        Column {
            id: content

            width: parent.width

            PageHeader { title: root.network ? root.network.name : "" }

            EncryptionComboBox {
                network: root.network
                enabled: false
                opacity: 1.0
                labelColor: Theme.secondaryHighlightColor
                valueColor: Theme.highlightColor // more important label
            }

            EapComboBox {
                network: root.network
                opacity: 1.0
            }

            PeapComboBox {
                network: root.network
                opacity: 1.0
            }

            InnerAuthComboBox {
                network: root.network
                opacity: 1.0
            }

            CACertChooser {
                id: caCertChooser
                network: root.network

                onFromFileSelected: pageStack.push(filePickerPage, { fieldName: 'caCert' })
            }

            IdentityField {
                id: identityField

                network: root.network
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: passphraseField.focus = true
            }

            PassphraseField {
                id: passphraseField

                network: root.network

                EnterKey.iconSource: "image://theme/icon-m-enter-" + (advancedSettingsColumn.focusable ? "next" : "close")
                EnterKey.onClicked: {
                    if (advancedSettingsColumn.focusable) {
                        advancedSettingsColumn.firstFocusableItem = true
                    } else {
                        parent.focus = true
                    }
                }
            }

            AdvancedSettingsColumn {
                id: advancedSettingsColumn
                network: root.network
            }
        }
        VerticalScrollDecorator {}
    }

    Component {
        id: filePickerPage

        FilePickerPage {
            nameFilters: [ '*.crt', '*.pem' ]
            property string fieldName
            onSelectedContentPropertiesChanged: {
                root.network[fieldName] = CertHelper.readCert(selectedContentProperties.filePath, 'CERTIFICATE')
            }
        }
    }
}
