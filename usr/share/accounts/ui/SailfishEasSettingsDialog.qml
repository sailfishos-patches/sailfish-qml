import QtQuick 2.6
import Sailfish.Silica 1.0

Dialog {
    id: root

    property alias accountId: settingsDisplay.accountId
    property Item connectionSettings
    property bool oauthEnabled

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
            oauthEnabled: root.oauthEnabled
            anchors.top: header.bottom
            isNewAccount: true
            accountManager: accountCreationAgent.accountManager
            accountProvider: accountCreationAgent.accountProvider
            autoEnableAccount: true
            connectionSettings: root.connectionSettings
            busyPage: accountCreationAgent.busyPageInstance

            onAccountSaveCompleted: {
                accountCreationAgent.delayDeletion = false
            }
        }
        VerticalScrollDecorator {}
    }
}
