import QtQuick 2.6
import org.nemomobile.systemsettings 1.0
import Sailfish.Silica 1.0
import Sailfish.Secrets 1.0 as Secrets
import Sailfish.Crypto 1.0 as Crypto
import Sailfish.Secrets.Ui 1.0

Page {
    id: page

    readonly property bool healthCheckDone: (healthCheckReq.status === Secrets.Request.Finished) && (healthCheckReq.result.code === Secrets.Result.Succeeded)
    readonly property alias healthCheckOk: healthCheckReq.isHealthy

    Component.onCompleted: {
        healthCheckReq.startRequest()
    }

    Crypto.CryptoManager {
        id: cryptoMgr
    }

    Secrets.SecretManager {
        id: secretMgr
    }

    StorageNotification {
        id: storageErrorNotification
    }

    SecretsErrorNotification {
        id: secretsErrorNotification
    }

    Secrets.HealthCheckRequest {
        id: healthCheckReq
        manager: secretMgr

        onStatusChanged: {
            if (status === Secrets.Request.Finished) {
                console.log("salt data health:", saltDataHealth)
                console.log("masterlock health:", masterlockHealth)
            }
        }
        onResultChanged: {
            if (status === Secrets.Request.Finished) {
                if (result.code !== Secrets.Result.Succeeded) {
                    console.warn("error during health check, resultcode:", result.code, "errorcode:", result.errorCode)
                }

                // If this was after a reset, re-enable the reset item
                if (dataCorruptionViewLoader.item !== null) {
                    dataCorruptionViewLoader.item.enabled = true;
                }
            }
        }
    }

    Connections {
        target: Qt.application
        onStateChanged: {
            if (Qt.application.state === Qt.ApplicationActive) {
                console.log("app activated, starting health check")
                healthCheckReq.startRequest()
            }
        }
    }

    SecretPluginsModel {
        id: secretPlugins
        secretManager: secretMgr
        filters: SecretPluginsModel.EncryptedStorage

        onError: secretsErrorNotification.show(error)
    }

    InfoLabel {
        anchors.centerIn: parent
        enabled: !healthCheckDone && (healthCheckReq.status === Secrets.Request.Finished) && (healthCheckReq.result.code !== Secrets.Result.Succeeded)
        opacity: enabled ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator { duration: 400 }}
        text: {
            //: Shown when the initial health check fails when the user opens the Keys page in Settings.
            //% "Error during secrets health check."
            return qsTrId("secrets_ui-la-healthcheck_error")
        }
    }

    InfoLabel {
        anchors.centerIn: parent
        enabled: healthCheckDone && healthCheckOk && (secretPlugins.count === 0)
        opacity: enabled ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator { duration: 400 }}
        // A bit misleading text is no plugins but IMO close enough for now.
        text: {
            //% "No keys"
            return qsTrId("secrets_ui-la-no_keys")
        }
    }

    SilicaListView {
        anchors.fill: parent
        enabled: healthCheckDone && healthCheckOk && (secretPlugins.count > 0)
        opacity: enabled ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator { duration: 400 }}

        model: !secretPlugins.masterLocked ? secretPlugins : null
        footer: Item {
            width: 1
            height: Theme.paddingLarge
        }

        InfoLabel {
            anchors.verticalCenter: parent.verticalCenter
            //% "Oops, something went wrong. No secret storages installed on the device"
            text: qsTrId("secrets_ui-la-secrets_ui-la-no_secret_storages")
            opacity: secretPlugins.ready && secretPlugins.count === 0 ? 1.0 : 0.0
            Behavior on opacity { FadeAnimator { duration: 400 }}
        }

        header: Column {
            id: column

            width: parent.width

            PageHeader {
                //% "Keys"
                title: qsTrId("secrets_ui-he-keys")
            }

            MasterLockHeader {
                secrets: secretPlugins
            }

            Item {
                width: 1
                height: Theme.paddingMedium
            }
        }

        delegate: PluginKeysItem {
            populated: secretPlugins.populated
            openMenuOnClick: true
            editMode: true
            cryptoManager: cryptoMgr
            secretManager: secretMgr
            onPluginLockCodeRequest: secretPlugins.pluginLockCodeRequest(pluginName, requestType)
            onStorageError: storageErrorNotification.show(error)
            onError: secretsErrorNotification.show(error)
        }

        VerticalScrollDecorator {}
    }

    Timer {
        id: healthCheckTimer
        interval: 2000
        onTriggered: {
            // This will check if everything is OK and trigger the necessary properties to change,
            // so the proper UI will appear after this.
            healthCheckReq.startRequest()
        }
    }

    Loader {
        id: dataCorruptionViewLoader
        asynchronous: true
        enabled: healthCheckDone && !healthCheckOk
        active: enabled
        opacity: enabled ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator { duration: 400 }}
        width: parent.width
        source: "DataCorruptionView.qml"
        onActiveChanged: {
            if (active) {
                // Should never destroy the created item once it becomes active
                active = true
            }
        }
        onItemChanged: {
            if (item !== null) {
                item.success.connect(function() {
                    // Give some time for the secrets service to restart properly before we perform the health check
                    console.log("secrets data reset successfully, starting health check in", healthCheckTimer.interval, "ms")
                    healthCheckTimer.start()
                });
                item.started.connect(function() {
                    console.log("secrets data reset started")
                    item.enabled = false
                });
            }
        }
    }
}
