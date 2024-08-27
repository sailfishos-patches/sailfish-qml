/*
 * Copyright (C) 2022 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

AccountCredentialsAgent {
    id: accountCreationAgent

    function _start() {
        if (initialPage.status != PageStatus.Active || account.status != Account.Initialized) {
            return
        }
        var sessionData = {
            "ClientId": keyProvider.clientId(),
            "ExtraParams": {
                // Require email address to match the previous address
                "login_hint": account.configurationValue("", "connection/emailaddress"),
                "hsu": "1" // Prevent selecting another account instead
            }
        }
        initialPage.prepareAccountCredentialsUpdate(account, accountCreationAgent.accountProvider,
                                                    "sailfisheas-oauth-email", sessionData)
    }

    Account {
        id: account
        identifier: accountCreationAgent.accountId

        onStatusChanged: {
            accountCreationAgent._start()
        }
    }

    StoredKeyProvider {
        id: keyProvider

        function clientId() {
            return keyProvider.storedKey("sailfisheas", "", "client_id")
        }
    }

    initialPage: OAuthAccountSetupPage {
        onStatusChanged: {
            accountCreationAgent._start()
        }

        onAccountCredentialsUpdated: {
            accountCreationAgent.credentialsUpdated(accountCreationAgent.accountId)
            accountCreationAgent.goToEndDestination()
        }

        onAccountCredentialsUpdateError: {
            accountCreationAgent.credentialsUpdateError(errorMessage)
        }
    }
}

