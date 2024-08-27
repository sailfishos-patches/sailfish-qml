/****************************************************************************************
**
** Copyright (c) 2018 - 2021 Jolla Ltd.
** Copyright (c) 2021 Open Mobile Platform LLC.
** All rights reserved.
**
** License: Proprietary.
**
****************************************************************************************/
import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Secrets 1.0
import Sailfish.Secrets.Ui 1.0
import Sailfish.Crypto 1.0
import Sailfish.FileManager 1.0 as SailfishFileManager
import Sailfish.Gallery 1.0
import Sailfish.TransferEngine 1.0
import Sailfish.Share 1.0
import Sailfish.Lipstick 1.0
import Nemo.Notifications 1.0
import Nemo.FileManager 1.0
import Nemo.DBus 2.0

Page {
    id: root

    property var shareActionConfiguration
    property var _fileToSign

    signal signed

    onSigned: {
        signer.shareToEmail(root._fileToSign, signer.getSignaturePath(root._fileToSign))
    }

    Component.onCompleted: {
        shareAction.loadConfiguration(shareActionConfiguration)
        _fileToSign = shareAction.resources[0] || ""
    }

    ShareAction {
        id: shareAction
    }

    BusyPlaceholder {
        id: busyPlaceholder
        anchors.centerIn: parent
        indicatorSize: BusyIndicatorSize.Large
        active: signer.busy
        spacing: Theme.paddingMedium

        text: {
            if (signer.busy) {
                //% "Signing, this might take a while"
                return qsTrId("secrets_ui-la_signing_busy_state")
            }
            return ""
        }
    }

    ProgressBar {
        anchors {
            top: busyPlaceholder.bottom
            topMargin: Theme.paddingMedium
        }
        minimumValue: 0
        maximumValue: signer.totalBytesToProcess
        value: signer.processedBytes
        width: parent.width
        visible: opacity > 0
        opacity: signer.busy ? 1.0 : 0.0
        Behavior on opacity { FadeAnimation {}}
    }

    CryptoManager {
        id: cryptoMgr
    }

    SecretManager {
        id: secretMgr
    }

    Signer {
        id: signer
        cryptoManager: cryptoMgr
        onSigningDone: page.signed()
    }

    SecretPluginsModel {
        id: secretPlugins
        secretManager: secretMgr
        filters: SecretPluginsModel.EncryptedStorage

        onError: secretsErrorNotification.show(error)
    }

    StorageNotification {
        id: storageErrorNotification
    }

    SecretsErrorNotification {
        id: secretsErrorNotification
    }

    SilicaListView {
        anchors.fill: parent
        enabled: !busyPlaceholder.active && secretPlugins.count > 0
        opacity: enabled ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator { duration: 400 }}
        model: !secretPlugins.masterLocked ? secretPlugins : null

        header: Column {
            width: parent.width

            PageHeader {
                //% "Sign"
                title: qsTrId("secrets_ui-he-sign")
            }

            SailfishFileManager.FileInfoItem {
                fileInfo: FileInfo { url: root._fileToSign }
            }

            Label {
                //% "Select existing or add new key to use to digitally sign the document"
                text: qsTrId("secrets_ui-la_select_or_import_key_to_sign")
                font.pixelSize: Theme.fontSizeSmall
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                color: Theme.secondaryHighlightColor
                //storedKeysModel.count > 0
                visible: false
            }

            SectionHeader {
                //% "Keys"
                text: qsTrId("secrets_ui-he-keys")
            }

            MasterLockHeader {
                secrets: secretPlugins
            }

            Item {
                width: 1
                height: Theme.paddingMedium
            }
        }

        ViewPlaceholder {
            //% "Import or generate key to use to sign the document"
            text: qsTrId("secrets_ui-la-import_or_generate_key_to_sign")
            visible: false
        }

        delegate: PluginKeysItem {
            populated: secretPlugins.populated
            cryptoManager: cryptoMgr
            secretManager: secretMgr
            onPluginLockCodeRequest: secretPlugins.pluginLockCodeRequest(pluginName, requestType)
            onStorageError: storageErrorNotification.show(error)
            onError: secretsErrorNotification.show(error)
            onClicked: signer.sign(root._fileToSign, key, digest)
        }

        VerticalScrollDecorator {}
    }
}
