/*
 * Copyright (c) 2016 - 2020 Jolla Ltd.
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
        serviceName: "jabber"
        applicationName: "Jolla"
        credentialsName: "Jolla"
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

