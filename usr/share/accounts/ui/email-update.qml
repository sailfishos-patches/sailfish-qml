/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import com.jolla.settings.accounts 1.0
import Sailfish.Accounts 1.0

AccountCredentialsAgent {
    id: root

    canCancelUpdate: true

    initialPage: CredentialsUpdateDialog {
        id: update
        serviceName: accountProvider.serviceNames[0]
        applicationName: "Jolla"
        credentialsName: pop3 ? "pop3/CredentialsId" : "imap4/CredentialsId"
        account.identifier: root.accountId
        providerIcon: root.accountProvider.iconName
        providerName: root.accountProvider.displayName
        property bool pop3

        onCredentialsUpdated: {
            root.credentialsUpdated(identifier)
            root.goToEndDestination()
        }

        onCredentialsUpdateError: root.credentialsUpdateError(message)

        Connections {
            target: update.account
            onStatusChanged: {
                if (update.account.status === Account.Initialized) {
                    // Type 0 is imap; type 1 is pop3
                    // Default to imap
                    update.pop3 = (update.account.configurationValue(update.serviceName, "incomingServerType") === 1)
                }
            }
        }
    }
}
