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
        var props = {
            "accessToken": responseData["AccessToken"],
            "accountId": accountId
        }
        var _accountSetup = accountSetupComponent.createObject(root, props)
        _accountSetup.done.connect(function() {
            accountCreated(accountId)
            _goToSettings(accountId)
        })
        _accountSetup.error.connect(function() {
            //: Error which is displayed when the user attempts to create a duplicate OneDrive account
            //% "You have already added a OneDrive account for user %1."
            var duplicateAccountError = qsTrId("jolla_settings_accounts_extensions-la-onedrive_duplicate_account").arg(root._existingUserName)
            accountCreationError(duplicateAccountError)
            _oauthPage.done(false, AccountFactory.BadParametersError, duplicateAccountError)
        })
    }

    function _goToSettings(accountId) {
        if (_settingsDialog != null) {
            _settingsDialog.destroy()
        }
        _settingsDialog = settingsComponent.createObject(root, {"accountId": accountId})
        pageStack.animatorReplace(_settingsDialog)
    }

    initialPage: AccountCreationLegaleseDialog {
        //: The text explaining how user's data will be backed up to OneDrive
        //% "When you add a OneDrive account, information from this device will be able to be backed up to OneDrive cloud storage service.<br><br>Adding a OneDrive account on your device means that you agree to OneDrive's Terms of Service."
        legaleseText: qsTrId("jolla_settings_accounts_extensions-la-onedrive-consent_text")

        //: Button which the user presses to view OneDrive Terms Of Service webpage
        //% "OneDrive Terms of Service"
        externalUrlText: qsTrId("jolla_settings_accounts_extensions-bt-onedrive_terms")
        externalUrlLink: "https://www.microsoft.com/en-us/servicesagreement/"

        onStatusChanged: {
            if (status == PageStatus.Active) {
                if (_oauthPage != null) {
                    _oauthPage.destroy()
                }
                _oauthPage = oAuthComponent.createObject(root)
                acceptDestination = _oauthPage
            }
        }
    }

    AccountFactory {
        id: accountFactory
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
                id: account
                identifier: accountSetup.accountId
                onStatusChanged: {
                    if (status === Account.Initialized || status === Account.Synced) {
                        if (!accountSetup.hasSetName) {
                            getProfileInfo()
                        } else {
                            accountSetup.done()
                        }
                    } else if (status === Account.Invalid && accountSetup.hasSetName) {
                        accountSetup.error()
                    }
                }
            }

            function getProfileInfo() {
                var doc = new XMLHttpRequest()
                doc.onreadystatechange = function() {
                    if (doc.readyState === XMLHttpRequest.DONE) {
                        if (doc.status === 200) {
                            var user = JSON.parse(doc.responseText)
                            var name = user.name
                            var userId = user.id

                            if (userId == null) {
                                // something went wrong, can't identify user
                                accountSetup.error()
                                return
                            }

                            if (name == null) {
                                name = ""
                            }

                            if (accountFactory.findAccount(
                                    "onedrive",
                                    "",
                                    "default_credentials_id",
                                    userId) !== 0) {
                                // this account already exists. show error dialog.
                                hasSetName = true
                                root._existingUserName = name
                                newAccount.remove()
                                accountSetup.error()
                                return
                            }

                            newAccount.setConfigurationValue("", "default_credentials_username", name)
                            newAccount.setConfigurationValue("", "default_credentials_id", userId)
                            newAccount.displayName = name
                            accountSetup.hasSetName = true
                            newAccount.sync()
                        } else {
                            console.log("Failed to query OneDrive user, error: " + doc.status)
                            accountSetup.done()
                        }
                    }
                }

                var url = "https://apis.live.net/v5.0/me?access_token=" + accessToken
                doc.open("GET", url)
                doc.send()
            }
        }
    }

    Component {
        id: oAuthComponent
        OAuthAccountSetupPage {
            Component.onCompleted: {
                var sessionData = {
                    "ClientId": keyProvider.storedKey("onedrive", "", "client_id"),
                    "ClientSecret": keyProvider.storedKey("onedrive", "", "client_secret")
                }
                prepareAccountCreation(root.accountProvider, "onedrive-sync", sessionData)
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

                OneDriveSettingsDisplay {
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
