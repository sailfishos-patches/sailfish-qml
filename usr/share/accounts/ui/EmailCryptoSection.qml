import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Crypto 1.0

Item {
    id: root

    property alias ready: pluginChecker.ready
    readonly property bool available: pluginChecker.available && emailAddress.length > 0

    property string emailAddress
    property string identity
    readonly property string pluginName: comboSignature.status == Loader.Ready ? comboSignature.item.pluginName : ""
    readonly property string keyIdentifier: comboSignature.status == Loader.Ready ? comboSignature.item.keyIdentifier : ""
    property string defaultKey

    // Whole column is shown only if the Secrets/Crypto framework is installed
    opacity: ready ? 1. : 0.
    visible: opacity > 0.
    Behavior on opacity { FadeAnimator {} }

    width: parent.width
    height: header.height
        + (comboSignature.item ? comboSignature.item.height : 0)
        + (pluginChecker.visible ? pluginChecker.height : 0)

    onAvailableChanged: {
        comboSignature.setSource("EmailCryptoKeySelection.qml", {
            "emailAddress": emailAddress,
            "identity": identity,
            "defaultKey": defaultKey})
    }

    SectionHeader {
        id: header
        //: Email cryptographic signature settings
        //% "Digital signature"
        text: qsTrId("settings-accounts-he-crypto_signature")
    }

    Loader {
        // Combobox with available keys for this email.
        id: comboSignature
        width: parent.width
        anchors.top: header.bottom
    }
    // Placeholder in case of missing plugin
    Label {
        id: pluginChecker
        property bool ready
        property bool available

        //% "No plugin for signature"
        text: qsTrId("settings-accounts-la-signature_not_available")
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Theme.fontSizeMedium
        anchors.top: header.bottom
        x: Theme.horizontalPageMargin
        width: parent.width - 2 * x
        color: Theme.secondaryHighlightColor
        visible: !available

        CryptoManager {
            id: cryptoManager
        }
        PluginInfoRequest {
            manager: cryptoManager
            onCryptoPluginsChanged: {
                for (var i = 0; i < cryptoPlugins.length && !pluginChecker.available; i++) {
                    if (cryptoPlugins[i].name == "org.sailfishos.crypto.plugin.gnupg.openpgp"
                        && (cryptoPlugins[i].statusFlags & PluginInfo.Available)) {
                        pluginChecker.available = true
                    }
                }
                pluginChecker.ready = true
            }
            Component.onCompleted: startRequest()
        }
    }
}
