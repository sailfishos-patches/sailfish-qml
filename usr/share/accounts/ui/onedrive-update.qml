import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

AccountCredentialsAgent {
    id: root

    function _start() {
        if (initialPage.status != PageStatus.Active || account.status != Account.Initialized) {
            return
        }
        var sessionData = {
            "ClientId": keyProvider.storedKey("onedrive", "", "client_id"),
            "ClientSecret": keyProvider.storedKey("onedrive", "", "client_secret")
        }
        initialPage.prepareAccountCredentialsUpdate(account, root.accountProvider, "onedrive-sync", sessionData)
    }

    Account {
        id: account
        identifier: root.accountId

        onStatusChanged: {
            root._start()
        }
    }

    StoredKeyProvider {
        id: keyProvider
    }

    initialPage: OAuthAccountSetupPage {
        onStatusChanged: {
            root._start()
        }

        onAccountCredentialsUpdated: {
            root.credentialsUpdated(root.accountId)
            root.goToEndDestination()
        }

        onAccountCredentialsUpdateError: {
            root.credentialsUpdateError(errorMessage)
        }
    }
}
