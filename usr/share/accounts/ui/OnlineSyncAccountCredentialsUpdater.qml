/*
 * Copyright (c) 2014 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

AccountCredentialsAgent {
    id: root

    property AccountSyncManager _syncManager: AccountSyncManager {}

    canCancelUpdate: true

    initialPage: CredentialsUpdateDialog {
        id: credentialsUpdateDialog

        property string webdavUrl
        property string ignoreSslErrors
        property bool _needsInit: status === PageStatus.Active
                                  && account.status === Account.Initialized

        function _init() {
            var services = account.supportedServiceNames
            for (var i = 0; i < services.length; i++) {
                var service = root.accountManager.service(services[i])
                if (!account.isEnabledWithService(service.name)) {
                    continue
                }

                // Set the service to use for sign-in
                credentialsUpdateDialog.serviceName = service.name

                // All services should have these configuration values set
                var serviceConfig = account.configurationValues(service.name)
                if (!serviceConfig["server_address"]) {
                    console.log("Cannot find server configuration in service:", service.name)
                } else {
                    webdavUrl = serviceConfig["server_address"] + (serviceConfig["webdav_path"] || "")
                    ignoreSslErrors = serviceConfig["ignore_ssl_errors"]
                }
                _needsInit = false
                return
            }

            //% "No services are enabled for this account!"
            credentialsUpdateDialog.setBusyStatus(false, qsTrId("settings-accounts-la-no_services_enabled"))
        }

        applicationName: "Jolla"
        credentialsName: "Jolla"
        account.identifier: root.accountId
        providerIcon: root.accountProvider.iconName
        providerName: root.accountProvider.displayName

        onCredentialsUpdated: {
            //% "Updating account details"
            credentialsUpdateDialog.setBusyStatus(true, qsTrId("settings-accounts-la-updating_account_details"))

            accountAuthenticator.signIn(identifier, credentialsUpdateDialog.serviceName)
        }
        onCredentialsUpdateError: root.credentialsUpdateError(message)
        on_NeedsInitChanged: if (_needsInit) _init()
    }

    AccountAuthenticator {
        id: accountAuthenticator

        onSignInCompleted: {
            //: In the process of verifying the username/password entered by the user
            //% "Verifying credentials"
            credentialsUpdateDialog.setBusyStatus(true, qsTrId("settings-accounts-la-verifying_credentials"))

            sendAuthenticatedRequest(credentialsUpdateDialog.webdavUrl, credentials, credentialsUpdateDialog.ignoreSslErrors)
        }

        onSignInError: {
            credentialsUpdateDialog.setBusyStatus(false, errorString)
        }

        onAuthenticatedRequestFinished: {
            if (success) {
                root.credentialsUpdated(accountId)
                root.goToEndDestination()
            } else {
                credentialsUpdateDialog.setBusyStatus(false, errorString)
            }
        }
    }
}
