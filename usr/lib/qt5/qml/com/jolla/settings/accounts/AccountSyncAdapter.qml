/*
 * Copyright (c) 2013 - 2019 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Accounts 1.0
import Nemo.DBus 2.0
import Connman 0.2

QtObject {
    id: root

    // Backup profiles have schedules independent of general sync profiles for an account
    // so are normally synced separately.
    property var _excludedServiceTypes: ["storage"]

    property var _trackedObjects: ({})

    /*
        Syncs the profiles for the given account ID or Account instance.

        Warning: if any missing profiles are created, this will sync the account, so it should be
        synced before this function is called to avoid losing existing setting changes.
    */
    function triggerSync(accountIdOrObject) {
        if (!accountIdOrObject) {
            console.log("AccountSyncAdapter.qml: cannot sync - invalid account ID or instance")
            return
        }
        if (_networkManagerFactory.instance.state !== "online") {
            _connectionSelector.call('openConnectionNow', ['wifi'])
            return
        }

        if (isNaN(accountIdOrObject)) {
            _triggerSyncForAccount(accountIdOrObject)
        } else {
            _triggerSyncForAccountId(accountIdOrObject)
        }
    }

    function _triggerSyncForAccount(account) {
        if (!account.enabled) {
            console.log("AccountSyncAdapter.qml: not syncing account", account.identifier, "because it is disabled")
            return
        }

        var waitForProfileCreation = createMissingProfiles(account)
        if (!waitForProfileCreation) {
            _doProfileSync(account)
        }
    }

    function _triggerSyncForAccountId(accountId) {
        var account = _accountInitializer.createObject(root, {"identifier": accountId, "destroyWhenSyncTriggered": true})
        _trackedObjects[account] = ''
        account.statusChanged.connect(function() {
            if (account.status === Account.Initialized) {
                _triggerSyncForAccount(account)
            }
        })
    }

    /*
        Warning: if any missing profiles are created, this will sync the account, so it should be
        synced before this function is called to avoid losing existing setting changes.

        E.g. if email app is not installed, the Google email profiles will not be created when the
        Google account is created.
      */
    function createMissingProfiles(account) {
        var syncObj = _missingProfileCreator.createObject(root, {"account": account})
        _trackedObjects[syncObj] = ''
        if (syncObj.createAllProfiles(account.identifier) > 0) {
            syncObj.done.connect(function() {
                delete _trackedObjects[syncObj]
                syncObj.destroy()
            })
            return true
        } else {
            delete _trackedObjects[syncObj]
            syncObj.destroy()
            return false
        }
    }

    function _doProfileSync(account) {
        var services = account.supportedServiceNames
        for (var i=0; i<services.length; i++) {
            var service = accountManager.service(services[i])
            if (_excludedServiceTypes.indexOf(service.serviceType) >= 0) {
                continue
            }

            if (account.isEnabledWithService(service.name)) {
                var profileIds = _syncManager.profileIds(account.identifier, service.name)
                for (var j = 0; j<profileIds.length; j++) {
                    buteoDaemon.call("startSync", profileIds[j])
                }
            }
        }
        _finishedWithAccount(account)
    }

    function _finishedWithAccount(account) {
        delete _trackedObjects[account]
        if (account.destroyWhenSyncTriggered === true) {
            account.destroy()
        }
    }

    property AccountManager accountManager: AccountManager {}

    property Component _accountInitializer: Component {
        Account {
            property bool destroyWhenSyncTriggered
        }
    }

    property Component _missingProfileCreator: Component {
        AccountSyncManager {
            property Account account

            signal done

            onAllProfilesCreated: {
                root._doProfileSync(account)
                done()
            }
            onAllProfileCreationError: {
                done()
            }
        }
    }

    property AccountSyncManager _syncManager: AccountSyncManager {}

    property DBusInterface buteoDaemon: DBusInterface {
        service: "com.meego.msyncd"
        path: "/synchronizer"
        iface: "com.meego.msyncd"
    }

    property DBusInterface _connectionSelector: DBusInterface {
        service: "com.jolla.lipstick.ConnectionSelector"
        path: "/"
        iface: "com.jolla.lipstick.ConnectionSelectorIf"
        signalsEnabled: true
    }

    property var _networkManagerFactory: NetworkManagerFactory {}
}
