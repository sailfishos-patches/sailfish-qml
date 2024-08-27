import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Secrets 1.0 as Secrets
import Sailfish.Crypto 1.0 as Crypto

Item {
    id: root
    property string emailAddress
    property string defaultKey
    property string identity
    readonly property string pluginName: cryptoCombo.currentItem ? cryptoCombo.currentItem.pluginName : ""
    readonly property string keyIdentifier: cryptoCombo.currentItem ? cryptoCombo.currentItem.keyIdentifier : ""

    width: parent.width
    height: Math.max(cryptoCombo.visible ? cryptoCombo.height : 0,
                     busyIndicator.visible ? busyIndicator.height : 0,
                     keyPlaceholder.visible ? keyPlaceholder.height : 0)

    ComboBox {
        id: cryptoCombo
        readonly property bool ready: pgpKeyFinder.status === Secrets.Request.Finished
            && smimeKeyFinder.status === Secrets.Request.Finished
        readonly property bool isEmpty: keyListModel.count === 0

        opacity: (ready && !isEmpty) ? 1. : 0.
        visible: opacity > 0.
        Behavior on opacity { FadeAnimator {} }
        //% "Outgoing emails"
        label: qsTrId("settings-accounts-la-outgoing_emails")
        currentIndex: 0
        menu: ContextMenu {
            MenuItem {
                property string pluginName: ""
                property string keyIdentifier: ""
                //% "No signature"
                text: qsTrId("settings-accounts-mi-no_signature")
            }
            Repeater {
                model: keyListModel
                delegate: MenuItem {
                    id: keyDelegate
                    property string pluginName: model.plugin
                    property string keyIdentifier: model.name
                    text: model.displayName
                    Component.onCompleted: {
                        if (keyIdentifier == defaultKey) {
                            cryptoCombo.currentItem = keyDelegate
                        }
                    }
                }
            }
        }
        ListModel {
            id: keyListModel
        }

        Secrets.SecretManager {
            id: secretManager
        }
        Secrets.FindSecretsRequest {
            id: pgpKeyFinder
            manager: secretManager
            collectionName: "import" // Trick because we don't know the collection name.
            filter: secretManager.constructFilterData({"email": emailAddress,
                                                       "canSign": "true"})
            filterOperator: Secrets.SecretManager.OperatorAnd
            storagePluginName: "org.sailfishos.crypto.plugin.gnupg.openpgp"
            Component.onCompleted: startRequest()
            onIdentifiersChanged: {
                for (var i = 0; i < identifiers.length; i++) {
                    //: %1: identifier of the signing key, usually 8 hexadecimal characters
                    //% "PGP key %1"
                    var displayName = qsTrId("settings-accounts-mi-pgp_key").arg(identifiers[i].name.slice(-8))
                    keyListModel.append({"name": identifiers[i].name,
                        "displayName": displayName,
                        "plugin": "libgpgme.so"}) // QMF plugin for PGP signatures.
                }
            }
        }
        Connections {
            target: keyPlaceholder.item
            onKeyRingChanged: pgpKeyFinder.startRequest()
        }
        Secrets.FindSecretsRequest {
            id: smimeKeyFinder
            manager: secretManager
            collectionName: "import" // Trick because we don't know the collection name.
            filter: secretManager.constructFilterData({"email": emailAddress,
                                                       "canSign": "true"})
            filterOperator: Secrets.SecretManager.OperatorAnd
            storagePluginName: "org.sailfishos.crypto.plugin.gnupg.smime"
            Component.onCompleted: startRequest()
            onIdentifiersChanged: {
                for (var i = 0; i < identifiers.length; i++) {
                    //: %1: identifier of the signing key, usually 8 hexadecimal characters
                    //% "S/MIME key %1"
                    var displayName = qsTrId("settings-accounts-mi-smime_key").arg(identifiers[i].name.slice(-8))
                    keyListModel.append({"name": identifiers[i].name,
                        "displayName": displayName,
                        "plugin": "libsmime.so"}) // QMF plugin for S/MIME signatures.
                }
            }
        }
    }

    BusyIndicator {
        id: busyIndicator
        size: BusyIndicatorSize.Medium
        anchors.horizontalCenter: parent.horizontalCenter
        visible: running
        running: !cryptoCombo.visible && !keyPlaceholder.visible
    }

    Loader {
        id: keyPlaceholder
        property alias identity: root.identity
        property alias emailAddress: root.emailAddress
        asynchronous: true
        sourceComponent: (cryptoCombo.ready && cryptoCombo.isEmpty)
            ? keyPlaceholderComponent : undefined

        width: parent.width
        opacity: status == Loader.Ready && !item.busy ? 1. : 0.
        visible: opacity > 0.
        Behavior on opacity { FadeAnimator {} }
    }
    Component {
        id: keyPlaceholderComponent
        Column {
            id: keyColumn
            property bool busy: keyGenerator.status === Crypto.Request.Active
                                || keyImporter.status === Crypto.Request.Active
            signal keyRingChanged()
            Label {
                //% "No key stored on the device for this email"
                text: qsTrId("settings-accounts-la-no_stored_key")
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeMedium
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                color: Theme.secondaryHighlightColor
            }
            Item {
                width: parent.width
                height: Theme.paddingLarge
            }
            ButtonLayout {
                Button {
                    //% "Generate"
                    text: qsTrId("settings-accounts-bt-generate_key")
                    onClicked: {
                        keyGenerator.startRequest()
                    }
                }
                Button {
                    //% "Import"
                    text: qsTrId("settings-accounts-bt-import_key")
                    onClicked: {
                        var picker = pageStack.push("Sailfish.Pickers.FilePickerPage", {
                            nameFilters: [ '*.asc', '*.gpg' ]
                            })

                        picker.selectedContentPropertiesChanged.connect(function() {
                            keyImporter.data = "file://" + picker.selectedContentProperties['filePath']
                            keyImporter.startRequest()
                        })
                    }
                }
            }
            Item {
                width: parent.width
                height: Theme.paddingSmall + errorLabel.height
                visible: errorLabel.text.length > 0
                Label {
                    id: errorLabel
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeSmall
                    x: Theme.horizontalPageMargin
                    y: Theme.paddingSmall
                    width: parent.width - 2 * x
                    color: Theme.secondaryColor
                }
            }

            Crypto.CryptoManager {
                id: cryptoManager
            }
            Crypto.GenerateStoredKeyRequest {
                id: keyGenerator
                manager: cryptoManager
                cryptoPluginName: "org.sailfishos.crypto.plugin.gnupg.openpgp"
                keyPairGenerationParameters: cryptoManager.constructRsaKeygenParams(
                    {"name": identity,
                     "email": emailAddress,
                     "expire": "2y"})
                keyTemplate: cryptoManager.constructKey("name",
                    "import", "org.sailfishos.crypto.plugin.gnupg.openpgp")
                onStatusChanged: {
                    if (status === Crypto.Request.Finished) {
                        if (result.code === Crypto.Result.Succeeded) {
                            keyColumn.keyRingChanged()
                            deleteKeyHelper.startRequest()
                            errorLabel.text = ""
                        } else {
                            console.log(result.code)
                            //% "Cannot generate key: %1"
                            errorLabel.text = qsTrId("settings-accounts-la-key_generation_error").arg(result.errorMessage)
                        }
                    }
                }
            }
            Crypto.ImportStoredKeyRequest {
                id: keyImporter
                manager: cryptoManager
                cryptoPluginName: "org.sailfishos.crypto.plugin.gnupg.openpgp"
                keyTemplate: cryptoManager.constructKey("name",
                    "import", "org.sailfishos.crypto.plugin.gnupg.openpgp")
                onStatusChanged: {
                    if (status === Crypto.Request.Finished) {
                        if (result.code === Crypto.Result.Succeeded) {
                            keyColumn.keyRingChanged()
                            deleteKeyHelper.startRequest()
                            errorLabel.text = ""
                        } else {
                            console.log(result.code)
                            //% "Cannot import key: %1"
                            errorLabel.text = qsTrId("settings-accounts-la-key_importation_error").arg(result.errorMessage)
                        }
                    }
                }
            }
            Crypto.DeleteStoredKeyRequest {
                /* This helper is a trick to delete the cached key in the fake
                   "import" collection, allowing to generate a new one again
                   later. */
                id: deleteKeyHelper
                manager: cryptoManager
                identifier: cryptoManager.constructIdentifier
                    ("name", "import", "org.sailfishos.crypto.plugin.gnupg.openpgp")
                 // Ensure that import is empty on start.
                Component.onCompleted: startRequest()
            }
        }
    }
}
