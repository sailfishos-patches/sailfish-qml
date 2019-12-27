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
            "ClientId": keyProvider.storedKey("dropbox", "dropbox-sharing", "client_id")
            // "client_secret": keyProvider.storedKey("dropbox", "", "client_secret"),
            // "response_type": "code"
            // secret is not needed with ResponseType = token (implicit grant)
        }
        initialPage.prepareAccountCredentialsUpdate(account, root.accountProvider, "dropbox-sharing", sessionData)
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
            if (pageContainer == null) { // page was popped
                cancelSignIn()
            }
        }
    }
}
