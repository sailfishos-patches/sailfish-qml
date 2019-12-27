/****************************************************************************
**
** Copyright (C) 2013-2019 Jolla Ltd.
** Copyright (C) 2019 Open Mobile Platform LLC
** Contact: Antti Seppälä <antti.seppala@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import org.nemomobile.configuration 1.0

Item {
    id: container

    property var eventFeedAccounts

    property var _autoSyncConfs: ({})

    signal refreshed
    signal accountEnabledChanged

    Timer {
        id: accountRefreshTimer
        interval: 10
        onTriggered: refreshAccountModel()
    }

    AccountManager {
        id: manager
        onAccountIdentifiersChanged: accountRefreshTimer.restart()
        onServiceTypeNamesChanged: accountRefreshTimer.restart()
        onProviderNamesChanged: accountRefreshTimer.restart()
        onServiceNamesChanged: accountRefreshTimer.restart()
        onAccountCreated: accountRefreshTimer.restart()
    }

    function refreshAccountModel() {
        var i

        if (!eventFeedAccounts) {
            eventFeedAccounts = new Array
        }

        var modified = false

        // maintain a list of all micro-blogging accounts
        for (i = 0; i < manager.accountIdentifiers.length; ++i) {
            if (!knownAccount(manager.accountIdentifiers[i])) {
                var account = manager.account(manager.accountIdentifiers[i])
                if (accountSupportsEventFeeds(account)) {
                    account.enabledChanged.connect(container.accountEnabledChanged)
                    account.enabledWithServiceChanged.connect(container.accountEnabledChanged)
                    eventFeedAccounts.push(account)

                    var confKey = "/desktop/lipstick-jolla-home/events/auto_sync_feeds/" + account.identifier
                    _autoSyncConfs[account.identifier] = autoSyncConfComponent.createObject(root, {"key": confKey})

                    modified = true
                }
            }
        }

        // clean away possible removed accounts
        for (i = 0; i < eventFeedAccounts.length; ++i) {
            var accountId = eventFeedAccounts[i].identifier
            if (manager.accountIdentifiers.indexOf(accountId) < 0) {
                eventFeedAccounts[i].enabledChanged.disconnect(container.accountEnabledChanged)
                eventFeedAccounts[i].enabledWithServiceChanged.disconnect(container.accountEnabledChanged)
                eventFeedAccounts.splice(i, 1)

                if (_autoSyncConfs[accountId] !== undefined) {
                    _autoSyncConfs[accountId].value = undefined
                    _autoSyncConfs[accountId].sync()
                    delete _autoSyncConfs[accountId]
                }

                i--
                modified = true
            }
        }

        // build a list of service types from the account list
        if (modified) {
            refreshed()
        }
    }

    function accountEnabledForEventFeeds(account) {
        if (!account.enabled) {
            return false
        }
        return account.isEnabledWithService(account.providerName + "-microblog")
                || account.isEnabledWithService(account.providerName + "-posts")
    }

    function accountSupportsEventFeeds(account) {
        for (var i = 0; i < account.supportedServiceNames.length; ++i) {
            var serviceName = account.supportedServiceNames[i]
            if (serviceName.indexOf("microblog") !== -1
                    || serviceName.indexOf("posts") !== -1) {
                return true
            }
        }

        return false
    }

    function knownAccount(identifier) {
        for (var i = 0; i < eventFeedAccounts.length; ++i) {
            if (eventFeedAccounts[i].identifier === identifier) {
                return true
            }
        }

        return false
    }

    function service(serviceName) {
        return manager.service(serviceName)
    }

    function shouldAutoSyncAccount(accountId) {
        var conf = _autoSyncConfs[accountId]
        return conf !== undefined && conf.value === true
    }

    Component {
        id: autoSyncConfComponent
        ConfigurationValue {}
    }

    Component.onCompleted: refreshAccountModel()
}
