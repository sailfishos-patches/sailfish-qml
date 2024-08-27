import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import Sailfish.Store 1.0
import com.jolla.settings.accounts 1.0

AccountSettingsAgent {
    id: root

    initialPage: Page {
        onPageContainerChanged: {
            if (pageContainer == null && !credentialsUpdater.running) {
                root.delayDeletion = true
                settingsDisplay.saveAccount()
            }
        }

        Component.onDestruction: {
            if (status == PageStatus.Active) {
                // app closed while settings are open, so save settings synchronously
                settingsDisplay.saveAccount(true)
            }
        }

        AccountCredentialsUpdater {
            id: credentialsUpdater
            onCredentialsUpdated: {
                // jolla account ID changes when credentials are updated, so enable the new
                // account, then reload it in the settings UI
                updatedAccount.identifier = 0
                updatedAccount.identifier = updatedAccountId
            }

            Account {
                id: updatedAccount
                onStatusChanged: {
                    if (status == Account.Initialized) {
                        var services = supportedServiceNames
                        for (var i in services) {
                            var service = root.accountManager.service(services[i])
                            enableWithService(service.name)
                        }
                        enabled = true
                        sync()
                    } else if (status == Account.Synced) {
                        settingsDisplay.reload(identifier)
                    }
                }
            }
        }

        SilicaFlickable {
            anchors.fill: parent
            contentHeight: header.height + settingsDisplay.height + Theme.paddingLarge

            StandardAccountSettingsPullDownMenu {
                visible: settingsDisplay.accountValid
                allowCredentialsUpdate: root.accountNotSignedIn

                allowSync: false
                onCredentialsUpdateRequested: credentialsUpdater.replaceWithCredentialsUpdatePage(settingsDisplay.accountId)
                onAccountDeletionRequested: {
                    root.accountDeletionRequested()
                    pageStack.pop()
                }
            }

            PageHeader {
                id: header
                title: root.accountsHeaderText
            }

            JollaAccountSettingsDisplay {
                id: settingsDisplay
                anchors.top: header.bottom
                accountManager: root.accountManager
                accountProvider: root.accountProvider
                accountId: root.accountId
                accountEnabledReadOnly: true

                onAccountSaveCompleted: {
                    root.delayDeletion = false
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.paddingLarge

                    Item {
                        width: 1
                        height: Theme.paddingLarge
                    }

                    Button {
                        anchors.horizontalCenter: parent.horizontalCenter
                        preferredWidth: Theme.buttonWidthLarge

                        //% "Terms of Service"
                        text: qsTrId("settings_accounts-he-terms_of_service")
                        onClicked: Qt.openUrlExternally("https://jolla.com/terms-of-service/")
                    }

                    Button {
                        anchors.horizontalCenter: parent.horizontalCenter
                        preferredWidth: Theme.buttonWidthLarge

                        //% "Privacy Policy"
                        text: qsTrId("settings_accounts-he-privacy_policy")
                        onClicked: Qt.openUrlExternally("https://jolla.com/privacy-policy/")
                    }

                    Button {
                        anchors.horizontalCenter: parent.horizontalCenter
                        preferredWidth: Theme.buttonWidthLarge

                        //% "Account web page"
                        text: qsTrId("settings_accounts-he-account_jolla_com_webpage")
                        onClicked: Qt.openUrlExternally("https://account.jolla.com/")
                    }

                    Button {
                        anchors.horizontalCenter: parent.horizontalCenter
                        preferredWidth: Theme.buttonWidthLarge
                        visible: StoreClient.isAvailable

                        //% "My Add-Ons"
                        text: qsTrId("settings_accounts-he-add_ons")
                        enabled: settingsDisplay.accountValid
                        onClicked: pageStack.animatorPush("com.jolla.settings.accounts.JollaAccountAddOnsPage")
                    }
                }
            }

            VerticalScrollDecorator {}
        }
    }
}
