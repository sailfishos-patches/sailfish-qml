import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

OnlineSyncAccountSettingsAgent {
    services: [
        accountManager.service("memotoo-carddav"),
        accountManager.service("memotoo-caldav")
    ]
}
