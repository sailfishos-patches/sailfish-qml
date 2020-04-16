/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import com.jolla.settings.accounts 1.0

AccountCredentialsAgent {
    id: root

    canCancelUpdate: true

    initialPage: CredentialsUpdateDialog {
        serviceName: "sailfisheas-email"
        applicationName: "Jolla"
        credentialsName: "ActiveSync"
        account.identifier: root.accountId
        providerIcon: root.accountProvider.iconName
        providerName: root.accountProvider.displayName

        onCredentialsUpdated: {
            root.credentialsUpdated(identifier)
            root.goToEndDestination()
        }

        onCredentialsUpdateError: root.credentialsUpdateError(message)
    }
}

