/*
 * Copyright (c) 2014 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

AccountCredentialsAgent {
    id: root

    property AccountSyncManager _syncManager: AccountSyncManager {}

    canCancelUpdate: true

    initialPage: CredentialsUpdateDialog {
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

        onOpened: {
            var services = account.supportedServiceNames
            for (var i = 0; i < services.length; i++) {
                var service = root.accountManager.service(services[i])
                var profileIds = root._syncManager.profileIds(account.identifier, service.name)
                if (profileIds.length > 0 && profileIds[0] !== "") {
                    serviceName = service.name
                    break
                }
            }
        }
    }
}
