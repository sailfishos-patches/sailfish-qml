import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    property alias isNewAccount: settingsDisplay.isNewAccount
    property alias accountId: settingsDisplay.accountId

    acceptDestination: accountCreationAgent.busyPageInstance
    acceptDestinationAction: PageStackAction.Push
    backNavigation: false

    onAccepted: {
        accountCreationAgent.delayDeletion = true
        settingsDisplay.saveAccount(false, true)
    }

    function accountSaveSync() {
        settingsDisplay.accountSaveSync()
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: header.height + settingsDisplay.height + Theme.paddingLarge

        DialogHeader {
            id: header
        }

        SailfishEasSettingsDisplay {
            id: settingsDisplay
            anchors.top: header.bottom
            accountManager: accountCreationAgent.accountManager
            accountProvider: accountCreationAgent.accountProvider
            autoEnableAccount: true
            connectionSettings: settings
            busyPage: accountCreationAgent.busyPageInstance

            onAccountSaveCompleted: {
                accountCreationAgent.delayDeletion = false
            }
        }
        VerticalScrollDecorator {}
    }
}
