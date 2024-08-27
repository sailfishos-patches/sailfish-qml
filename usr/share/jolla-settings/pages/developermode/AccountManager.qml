/*
 * Copyright (c) 2022 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Accounts 1.0

AccountManager {
    function developerAccountProvider() {
        var names = providerNames
        for (var i = 0; i < names.length; ++i) {
            var accountProvider = provider(names[i])
            if (providerHasService(accountProvider, "developermode")) {
                return names[i]
            }
        }
        return ""
    }

    function providerHasService(provider, serviceName) {
        var serviceNames = provider.serviceNames
        for (var i = 0; i < serviceNames.length; ++i) {
            var accountService = service(serviceNames[i])
            if (accountService.serviceType == serviceName) {
                return true
            }
        }
        return false
    }

    function hasAccountForProvider(accountIds, providerName) {
        for (var i = 0; i < accountIds.length; ++i) {
            if (account(accountIds[i]).providerName == providerName) {
                return true
            }
        }
        return false
    }

    Component.onCompleted: root.developerAccountProvider = developerAccountProvider()
    onProviderNamesChanged: root.developerAccountProvider = developerAccountProvider()
}
