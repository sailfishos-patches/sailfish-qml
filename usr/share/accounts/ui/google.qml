/*
 * Copyright (c) 2016 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0
import org.nemomobile.social 1.0

AccountCreationAgent {
    id: root

    property Item _oauthPage
    property Item _settingsDialog
    property QtObject _accountSetup
    property string _existingUserName

    function _handleAccountCreated(accountId, responseData) {
        var props = {
            "accessToken": responseData["AccessToken"],
            "accountId": accountId
        }
        _accountSetup = accountSetupComponent.createObject(root, props)
        _accountSetup.done.connect(function() {
            accountCreated(accountId)
            _goToSettings(accountId)
        })
        _accountSetup.error.connect(function() {
            //: Error which is displayed when the user attempts to create a duplicate Google account
            //% "You have already added a Google account for user %1."
            var duplicateAccountError = qsTrId("jolla_settings_accounts_extensions-la-google_duplicate_account").arg(root._existingUserName)
            accountCreationError(duplicateAccountError)
            _oauthPage.done(false, AccountFactory.BadParametersError, duplicateAccountError)
        })
    }

    function _goToSettings(accountId) {
        if (_settingsDialog != null) {
            _settingsDialog.destroy()
        }
        _settingsDialog = settingsComponent.createObject(root, {"accountId": accountId, "isNewAccount": true})
        pageStack.animatorReplace(_settingsDialog)
    }

    initialPage: AccountCreationLegaleseDialog {
        //: The text explaining how user's Google data will be used on the device
        //% "When you add a Google account, information from this account will be added to the device to provide a faster and better experience:<br><br> - Google contacts will be added to the People application and linked with existing contacts, and you'll be able to send and receive Gmail messages using the Email application.<br><br> - Google Calendar events will be added to the Calendar application, and modifications to those events will be synced back to the Google servers<br><br>Some of this data will be cached to make it available when offline. This cache can be cleared at any time disabling the relevant services on the account's settings page.<br><br>Adding a Google account on your device means that you agree to Google's Terms of Service."
        legaleseText: qsTrId("jolla_settings_accounts_extensions-la-google_consent_text")

        //: Button which the user presses to view Google Terms Of Service webpage
        //% "Google Terms of Service"
        externalUrlText: qsTrId("jolla_settings_accounts_extensions-bt-google_terms")
        externalUrlLink: "http://www.google.com/intl/en/policies/terms/"

        onStatusChanged: {
            if ((_oauthPage != null && status == PageStatus.Active)
                    || (_oauthPage != null && status == PageStatus.Deactivating && result == DialogResult.Rejected)) {
                // OAuth pages can't be reused as user must be taken back to initial sign-in page.
                _oauthPage.cancelSignIn()
                _oauthPage.destroy()
                _oauthPage = null
            }
            if (status == PageStatus.Active) {
                _oauthPage = oAuthComponent.createObject(root)
                acceptDestination = _oauthPage
            }
        }
    }

    AccountFactory {
        id: accountFactory
    }

    Component {
        id: oAuthComponent
        OAuthAccountSetupPage {
            Component.onCompleted: {
                var sessionData = {
                    "ClientId": keyProvider.storedKey("google", "google-sync", "client_id"),
                    "ClientSecret": keyProvider.storedKey("google", "google-sync", "client_secret"),
                    "ResponseType": "code",
                    "QueryItems": { "hl": Qt.locale().name }
                }
                prepareAccountCreation(root.accountProvider, "google-sync", sessionData)
            }
            onAccountCreated: {
                root._handleAccountCreated(accountId, responseData)
            }
            onAccountCreationError: {
                root.accountCreationError(errorMessage)
            }

            StoredKeyProvider {
                id: keyProvider
            }
        }
    }

    Component {
        id: accountSetupComponent
        QtObject {
            id: accountSetup
            property string accessToken
            property bool hasSetName
            property int accountId

            signal done()
            signal error()

            property Account newAccount: Account {
                identifier: accountSetup.accountId
                onStatusChanged: {
                    if (status == Account.Initialized || status == Account.Synced) {
                        if (!accountSetup.hasSetName) {
                            var queryItems = {"access_token": accountSetup.accessToken}
                            sni.arbitraryRequest(SocialNetwork.Get, "https://www.googleapis.com/oauth2/v2/userinfo", queryItems)
                        } else {
                            accountSetup.done()
                        }
                    } else if (status == Account.Invalid && accountSetup.hasSetName) {
                        accountSetup.error()
                    }
                }
            }
            property SocialNetwork sni: SocialNetwork {
                onArbitraryRequestResponseReceived: {
                    var userEmail = data["email"]
                    if (userEmail == undefined || userEmail == "") {
                        accountSetup.done()
                    } else {
                        // check to ensure that the account doesn't already exist
                        if (accountFactory.findAccount(
                                    "google",
                                    "",
                                    "default_credentials_username",
                                    userEmail) !== 0) {
                            // this account already exists.  display error dialog.
                            root._existingUserName = userEmail
                            accountSetup.hasSetName = true
                            newAccount.remove()
                        } else {
                            newAccount.displayName = userEmail
                            newAccount.setConfigurationValue("", "default_credentials_username", userEmail)
                            newAccount.setConfigurationValue("google-gmail", "emailaddress", userEmail)
                            newAccount.setConfigurationValue("google-gmail", "imap4/username", userEmail)
                            newAccount.setConfigurationValue("google-gmail", "smtp/smtpusername", userEmail)
                            accountSetup.hasSetName = true
                            newAccount.sync()
                        }
                    }
                }
            }
        }
    }

    Component {
        id: settingsComponent
        Dialog {
            property alias accountId: settingsDisplay.accountId
            property alias isNewAccount: settingsDisplay.isNewAccount

            acceptDestination: root.endDestination
            acceptDestinationAction: root.endDestinationAction
            acceptDestinationProperties: root.endDestinationProperties
            acceptDestinationReplaceTarget: root.endDestinationReplaceTarget
            backNavigation: false

            onAccepted: {
                root.delayDeletion = true
                settingsDisplay.saveAccountAndSync()
            }

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: header.height + settingsDisplay.height + Theme.paddingLarge

                DialogHeader {
                    id: header
                }

                GoogleSettingsDisplay {
                    id: settingsDisplay
                    anchors.top: header.bottom
                    accountManager: root.accountManager
                    accountProvider: root.accountProvider
                    autoEnableAccount: true

                    onAccountSaveCompleted: {
                        root.delayDeletion = false
                    }
                }

                VerticalScrollDecorator {}
            }
        }
    }
}
