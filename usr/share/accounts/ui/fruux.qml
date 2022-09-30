import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

OnlineSyncAccountCreationAgent {
    provider: accountProvider
    services: [
        accountManager.service("fruux-carddav"),
        accountManager.service("fruux-caldav")
    ]
    // can't load from the service without an account because a&sso doesn't support that.
    serverAddress: "https://dav.fruux.com"
}
