import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0

PresenceDetailsPage {
    // Load the presence information from the presence listener
    globalPresenceState: PresenceListener.globalPresenceState

    function getPresenceAccounts() {
        return PresenceListener.accounts
    }

    Component.onCompleted: updatePresenceModel()

    Connections {
        target: PresenceListener
        onAccountsChanged: scheduleUpdatePresenceModel()
    }
}
