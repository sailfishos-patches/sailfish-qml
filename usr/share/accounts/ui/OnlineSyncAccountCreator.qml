/*
 * Copyright (c) 2013 - 2019 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

QtObject {
    id: root

    property Provider provider
    property var services: []

    property string username
    property string password
    property string serverAddress
    property string addressbookPath
    property string calendarPath
    property string webdavPath
    property string imagesPath
    property string backupsPath
    property bool ignoreSslErrors
    property bool skipAuthentication
    property var servicesEnabledConfig: ({})

    signal success(int newAccountId)
    signal failed(int errorCode, string errorMessage)
    signal updateCreationStatus(string statusText)

    property bool _startedAccountCreation

    onFailed: {
        _startedAccountCreation = false
    }

    function start() {
        if (_startedAccountCreation) {
            return
        }

        _startedAccountCreation = true

        var servicesConfig = {}
        for (var i = 0; i < services.length; ++i) {
            var config = {}
            if (serverAddress != "") {
                config["server_address"] = serverAddress
            }

            var service = services[i]
            if (service.serviceType === "carddav") {
                if (addressbookPath != "") {
                    config["addressbook_path"] = addressbookPath
                }
            } else if (service.serviceType === "caldav") {
                if (calendarPath != "") {
                    config["calendar_path"] = calendarPath
                }
            } else if (service.name.search('-images$') >= 0) {
                if (imagesPath != "") {
                    config["images_path"] = imagesPath
                }
            } else if (service.serviceType === "storage") {
                if (backupsPath != "") {
                    config["backups_path"] = backupsPath
                }
            }

            if (webdavPath != "") {
                config["webdav_path"] = webdavPath
            }
            config["ignore_ssl_errors"] = ignoreSslErrors
            servicesConfig[service.name] = config
        }

        _accountFactory.createAccount(
                provider.name,
                "onlinesync-caldav",    // any onlinesync service name is fine
                username, password,
                username,
                servicesConfig,    // configuration map
                "Jolla",  // applicationName
                "",       // symmetricKey
                "Jolla")  // credentialsName
    }

    function cleanUp() {
        if (_newAccount.identifier > 0) {
            _newAccount.remove()
        }
    }

    function _findCalendarService() {
        for (var i = 0; i < services.length; ++i) {
            var service = services[i]
            if (service.serviceType === "caldav") {
                return service
            }
        }
        return null
    }

    property AccountFactory _accountFactory: AccountFactory {
        onError: {
            console.log("OnlineSync creation error:", message)
            root.failed(errorCode, message)
        }
        onSuccess: {
            // initialize the Account, then search for calendars
            _newAccount.identifier = newAccountId
        }
    }

    property Account _newAccount: Account {
        property bool triggeredCompletion
        onStatusChanged: {
            if (status == Account.Initialized) {
                // enable or disable services as required
                var needSync = false
                for (var i = 0; i < services.length; ++i) {
                    var service = services[i]
                    var enableService = root.servicesEnabledConfig[service.name] === true
                    if (!enableService && isEnabledWithService(service.name)) {
                        disableWithService(service.name)
                        needSync = true
                    } else if (enableService && !isEnabledWithService(service.name)) {
                        enableWithService(service.name)
                        needSync = true
                    }
                }
                if (needSync) {
                    sync()
                } else {
                    triggeredCompletion = true
                    _completeAccountCreation()
                }
            } else if (status == Account.Synced) {
                if (!triggeredCompletion) {
                    triggeredCompletion = true
                    _completeAccountCreation()
                }
            } else if (status == Account.Error) {
                console.log("failed to sync online sync account settings")
                remove()
                root.failed(error, errorMessage)
            }
        }

        function updateCalendars() {
            // enumerate calendars if CalDAV is enabled
            var caldav = root._findCalendarService()
            if (caldav && root.servicesEnabledConfig[caldav.name] === true) {
                if (root._calendarUpdater != null) {
                    root._calendarUpdater.destroy()
                }

                var serviceConfig = configurationValues(caldav.name)
                root._calendarUpdater = calendarUpdaterComponent.createObject(root)
                root._calendarUpdater.start(_newAccount,
                                            caldav.name,
                                            serviceConfig["server_address"],
                                            !!serviceConfig["ignore_ssl_errors"],
                                            calendarPath)
                return true
            }

            return false
        }

        function _completeAccountCreation() {
            // Validate the credentials with any enabled service
            for (var serviceName in root.servicesEnabledConfig) {
                if (!!root.servicesEnabledConfig[serviceName]) {
                    //: In the process of verifying the username/password entered by the user
                    //% "Verifying credentials"
                    var verifyingStatus = qsTrId("components_accounts-la-verifying_credentials")
                    //: In the process of creating the account with the specified details
                    //% "Creating account"
                    var creatingStatus = qsTrId("components_accounts-la-creating_account")
                    root.updateCreationStatus(root.skipAuthentication ? creatingStatus : verifyingStatus)

                    if (!root._accountAuthenticator) {
                        root._accountAuthenticator = _accountAuthenticatorComponent.createObject(root)
                    }
                    root._accountAuthenticator.signIn(_newAccount.identifier, serviceName)
                    return
                }
            }

            // Shouldn't happen, UI forces at least one service to be enabled.
            // Reuse the string from MinimumServiceEnabledNotification.
            //% "At least one service must be enabled"
            root.failed(AccountFactory.LoginError, qsTrId("settings-accounts-la-enable_at_least_one_service"))
        }
    }

    property QtObject _calendarUpdater
    property Component calendarUpdaterComponent: Component {
        CaldavAccountCalendarUpdater {
            onStatusChanged: {
                root.updateCreationStatus(statusText)
            }
            onSuccess: {
                root.success(_newAccount.identifier)
            }
            onError: {
                _newAccount.remove()
                root.failed(errorCode, errorString)
            }
        }
    }

    property QtObject _accountAuthenticator
    property Component _accountAuthenticatorComponent: Component {
        AccountAuthenticator {
            id: authenticator

            function _done(success, errorString) {
                if (success) {
                    if (!_newAccount.updateCalendars()) {
                        // No calendar update required, so emit success()
                        root.success(_newAccount.identifier)
                    }
                } else {
                    root.failed(AccountFactory.LoginError, errorString)
                }
            }

            onSignInCompleted: {
                if (root.skipAuthentication) {
                    authenticator._done(true, "skipped")
                } else if (root.provider.name == "nextcloud") {
                    sendOcsUserRequest(accountId, serviceName, credentials, root.ignoreSslErrors)
                } else {
                    sendAuthenticatedRequest(root.serverAddress + root.webdavPath, credentials, root.ignoreSslErrors)
                }
            }

            onSignInError: {
                _newAccount.remove()
                root.failed(AccountFactory.LoginError, errorString)
            }

            onAuthenticatedRequestFinished: authenticator._done(success, errorString)
            onOcsUserRequestFinished: authenticator._done(success, errorString)
        }
    }
}
