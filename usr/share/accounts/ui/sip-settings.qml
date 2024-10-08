import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

AccountSettingsAgent {
    id: root

    initialPage: Page {
        onPageContainerChanged: {
            if (pageContainer == null) {
                root.delayDeletion = true
                settingsDisplay.saveAccount()
            }
        }

        Component.onDestruction: {
            if (status == PageStatus.Active && !credentialsUpdater.running) {
                // app closed while settings are open, so save settings synchronously
                settingsDisplay.saveAccount(true)
            }
        }

        SilicaFlickable {
            anchors.fill: parent
            contentHeight: header.height + settingsDisplay.height + Theme.paddingLarge

            StandardAccountSettingsPullDownMenu {
                allowSync: false
                allowCredentialsUpdate: root.accountNotSignedIn

                onCredentialsUpdateRequested: credentialsUpdater.replaceWithCredentialsUpdatePage(root.accountId)
                onAccountDeletionRequested: {
                    root.accountDeletionRequested()
                    pageStack.pop()
                }
            }

            PageHeader {
                id: header
                title: root.accountsHeaderText
            }

            SIPSettingsDisplay {
                id: settingsDisplay
                anchors.top: header.bottom
                accountProvider: root.accountProvider
                accountId: root.accountId

                onAccountSaveCompleted: {
                    root.delayDeletion = false
                }
            }

            VerticalScrollDecorator {}
        }

        AccountCredentialsUpdater {
            id: credentialsUpdater
        }
    }
}
