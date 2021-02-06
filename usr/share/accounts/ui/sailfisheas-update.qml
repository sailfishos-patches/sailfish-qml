/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Accounts 1.0
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

        function increaseCredentialsCounter() {
            var _credentialsUpdateCounter = parseInt(account.configurationValue(serviceName, "credentials_update_counter"))
            _credentialsUpdateCounter++
            // Save a string since double is not supported in c++ side:  'Account::setConfigurationValues(): variant type  QVariant::double'
            account.setConfigurationValue(serviceName, "credentials_update_counter", _credentialsUpdateCounter.toString())
        }

        onCredentialsUpdated: {
            console.log("[jsa-eas] Credentials updated sucessfully")
            increaseCredentialsCounter()
            account.blockingSync()

            root.credentialsUpdated(identifier)
            root.goToEndDestination()
        }

        onCredentialsUpdateError: root.credentialsUpdateError(message)
    }
}

