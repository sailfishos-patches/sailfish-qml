import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

OnlineSyncAccountCreationAgent {
    provider: accountProvider
    services: [
        accountManager.service("onlinesync-carddav"),
        accountManager.service("onlinesync-caldav")
    ]
    showAdvancedSettings: true
}
