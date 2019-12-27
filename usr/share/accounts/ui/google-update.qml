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
            "ClientId": keyProvider.storedKey("google", "google-sync", "client_id"),
            "ClientSecret": keyProvider.storedKey("google", "google-sync", "client_secret"),
            "ResponseType": "code"
        }
        initialPage.prepareAccountCredentialsUpdate(account, root.accountProvider, "google-sync", sessionData)
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

        onPageContainerChanged: {
            if (pageContainer == null) {    // page was popped
                cancelSignIn()
            }
        }
    }
}
