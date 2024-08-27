import QtQuick 2.0
import Sailfish.Silica 1.0
import Connman 0.2
import Sailfish.Pickers 1.0
import Sailfish.Settings.Networking 1.0
import "../netproxy"

Dialog {
    id: root

    forwardNavigation: false
    canNavigateForward: false

    property QtObject network

    onStatusChanged: {
        if (status === PageStatus.Active) {
            caCertChooser.cancel()
            clientCertChooser.cancel()
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        PullDownMenu {
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

            DialogHeader {
                id: dialogHeader
                acceptText: ""

                //% "Save"
                cancelText: qsTrId("settings_network-he-save")

                Label {
                    parent: dialogHeader.extraContent
                    text: root.network ? root.network.name : ""
                    color: Theme.highlightColor
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    font {
                        pixelSize: Theme.fontSizeLarge
                        family: Theme.fontFamilyHeading
                    }
                    anchors {
                        right: parent.right
                        rightMargin: -Theme.horizontalPageMargin
                        verticalCenter: parent.verticalCenter
                    }

                    horizontalAlignment: Qt.AlignRight
                }
            }

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

                onFromFileSelected: pageStack.push(fileLoaderPage, { fieldName: 'caCert' })
            }

            ClientCertChooser {
                id: clientCertChooser
                network: root.network

                onKeyFromFileSelected: pageStack.push(filePickerPage, { fieldName: 'privateKeyFile', nameFilters: ['*.pem', '*.key', '*.p12', '*.pfx'] })
                onCertFromFileSelected: pageStack.push(filePickerPage, { fieldName: 'clientCertFile', nameFilters: ['*.pem', '*.crt'] })
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

            AnonymousIdentityField {
                id: anonymousIdentityField
                network: root.network
            }

            AdvancedSettingsColumn {
                id: advancedSettingsColumn
                network: root.network
                globalProxyConfigPage: Qt.resolvedUrl("../advanced-networking/mainpage.qml")
            }
        }
        VerticalScrollDecorator {}
    }

    Component {
        id: fileLoaderPage

        FilePickerPage {
            nameFilters: [ '*.crt', '*.pem' ]
            property string fieldName
            onSelectedContentPropertiesChanged: {
                root.network[fieldName] = CertHelper.readCert(selectedContentProperties.filePath, 'CERTIFICATE')
            }
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
