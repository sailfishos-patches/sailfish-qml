import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

AccountCreationAgent {
    id: root

    property Item _oauthPage
    property Item _settingsDialog
    property QtObject _accountSetup
    property string _existingUserName

    function _handleAccountCreated(accountId, responseData) {
        var screenName = responseData["ScreenName"]
        if (screenName == "") {
            accountCreated(accountId)
            _goToSettings(accountId)
        } else {
            var props = {
                "screenName": screenName,
                "accountId": accountId
            }
            _accountSetup = accountSetupComponent.createObject(root, props)
            _accountSetup.done.connect(function() {
                accountCreated(accountId)
                _goToSettings(accountId)
            })
            _accountSetup.error.connect(function() {
                //: Error which is displayed when the user attempts to create a duplicate Twitter account
                //% "You have already added a Twitter account for user %1."
                var duplicateAccountError = qsTrId("jolla_settings_accounts_extensions-la-twitter_duplicate_account").arg(root._existingUserName)
                accountCreationError(duplicateAccountError)
                root._oauthPage.done(false, AccountFactory.BadParametersError, duplicateAccountError)
            })
        }
    }

    function _goToSettings(accountId) {
        if (_settingsDialog != null) {
            _settingsDialog.destroy()
        }
        _settingsDialog = settingsComponent.createObject(root, {"accountId": accountId})
        pageStack.animatorReplace(_settingsDialog)
    }

    initialPage: AccountCreationLegaleseDialog {
        //: The text explaining how user's Twitter data will be used on the device
        //% "When you add a Twitter account, information from this account will be added to the device to provide a faster and better experience:<br><br> Tweets from your timeline will be added to Events, and you will be able to post Tweet updates on Twitter.<br><br> You will be able to share photos on Twitter.<br><br>Some of this data will be cached to make it available when offline. This cache can be cleared at any time by disabling the relevant services on the account settings page.<br><br>Adding a Twitter account on your device means that you agree to Twitter Terms of Service."
        legaleseText: qsTrId("jolla_settings_accounts_extensions-la-twitter_consent_text")

        //: Button which the user presses to view Twitter Terms Of Service webpage
        //% "Twitter Terms of Service"
        externalUrlText: qsTrId("jolla_settings_accounts_extensions-bt-twitter_terms")
        externalUrlLink: "https://mobile.twitter.com/tos"

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
                    "ConsumerKey": keyProvider.storedKey("twitter", "twitter-sync", "consumer_key"),
                    "ConsumerSecret": keyProvider.storedKey("twitter", "twitter-sync", "consumer_secret"),
                }
                prepareAccountCreation(root.accountProvider, "twitter-sync", sessionData)
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
            property string screenName
            property bool hasSetName
            property int accountId

            signal done()
            signal error()

            property Account newAccount: Account {
                identifier: accountSetup.accountId
                onStatusChanged: {
                    if (status == Account.Initialized || status == Account.Synced) {
                        if (!accountSetup.hasSetName) {
                            if (accountFactory.findAccount(
                                    "twitter",
                                    "",
                                    "default_credentials_username",
                                    accountSetup.screenName) !== 0) {
                                // this account already exists.  show error dialog.
                                root._existingUserName = screenName
                                hasSetName = true
                                remove()
                            } else {
                                hasSetName = true
                                displayName = screenName
                                setConfigurationValue("", "default_credentials_username", screenName)
                                sync()
                            }
                        } else {
                            accountSetup.done()
                        }
                    } else if (status == Account.Invalid && accountSetup.hasSetName) {
                        accountSetup.error()
                    }
                }
            }
        }
    }

    Component {
        id: settingsComponent
        Dialog {
            property alias accountId: settingsDisplay.accountId

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
                contentHeight: header.height + settingsDisplay.height

                DialogHeader {
                    id: header
                }

                TwitterSettingsDisplay {
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
