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
            //: The text explaining how user has already added dropbox account for that user
            //% "You have already added a Dropbox account for user %1."
            var duplicateAccountError = qsTrId("jolla_settings_accounts_extensions-la-dropbox-duplicate_text").arg(root._existingUserName)
            accountCreationError(duplicateAccountError)
            root._oauthPage.done(false, AccountFactory.BadParametersError, duplicateAccountError)
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
        //: The text explaining how user's data will be backed up to Dropbox
        //% "When you add a Dropbox account, information from this device will be able to be backed up to Dropbox's cloud storage service.<br><br>Adding a Dropbox account on your device means that you agree to Dropbox's Terms of Service."
        legaleseText: qsTrId("jolla_settings_accounts_extensions-la-dropbox-consent_text")

        //: Button which the user presses to view Dropbox Terms Of Service webpage
        //% "Dropbox Terms of Service"
        externalUrlText: qsTrId("jolla_settings_accounts_extensions-bt-dropbox_terms")
        externalUrlLink: "https://www.dropbox.com/privacy#terms"

        onStatusChanged: {
            if ((_oauthPage != null && status === PageStatus.Active)
                    || (_oauthPage != null && status === PageStatus.Deactivating && result === DialogResult.Rejected)) {
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
                    "ClientId": keyProvider.storedKey("dropbox", "dropbox-sharing", "client_id")
                    // "client_secret": keyProvider.storedKey("dropbox", "", "client_secret"),
                    // "response_type": "code"
                }
                prepareAccountCreation(root.accountProvider, "dropbox-sharing", sessionData)
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
            property string screenName
            property bool hasSetName
            property int accountId

            signal done()
            signal error()

            property Account newAccount: Account {
                identifier: accountSetup.accountId
                onStatusChanged: {
                    if (status === Account.Initialized || status === Account.Synced) {
                        if (!accountSetup.hasSetName) {
                            var req = new XMLHttpRequest()
                            req.onreadystatechange = function() {
                                if (req.readyState === XMLHttpRequest.DONE) {
                                    var objectArray = JSON.parse(req.responseText)
                                    if (objectArray.errors !== undefined) {
                                        console.log("Error fetching user data: " + objectArray.errors[0].message)
                                        accountSetup.error()
                                    } else {
                                        var name = objectArray["name"]["display_name"]
                                        var email = objectArray["email"]
                                        var uid = objectArray["account_id"]
                                        if (uid !== undefined && !(typeof uid === 'string' || uid instanceof String)) {
                                            // might be a number, which gets converted to a double
                                            // and accounts&sso cannot store double settings values.
                                            uid = uid.toString()
                                        }
                                        if (uid !== undefined && uid !== "") {
                                            if (accountFactory.findAccount(
                                                        "dropbox",
                                                        "",
                                                        "dropbox_uid",
                                                        uid) !== 0) {
                                                // this account already exists.  display error dialog.
                                                accountSetup.hasSetName = true
                                                newAccount.remove()
                                                return
                                            }
                                            newAccount.setConfigurationValue("", "dropbox_uid", uid)
                                        }

                                        if (email !== undefined && email !== "") {
                                            if (accountFactory.findAccount(
                                                        "dropbox",
                                                        "",
                                                        "dropbox_email",
                                                        uid) !== 0) {
                                                // this account already exists.  display error dialog.
                                                accountSetup.hasSetName = true
                                                newAccount.remove()
                                                return
                                            }
                                            newAccount.setConfigurationValue("", "dropbox_email", email)
                                            newAccount.displayName = email
                                            newAccount.setConfigurationValue("", "default_credentials_username", email)
                                            root._existingUserName = name
                                            accountSetup.hasSetName = true
                                        }

                                        if (name !== undefined && name !== "") {
                                            newAccount.sync()
                                            accountSetup.done()
                                        } else {
                                            console.log("Error fetching user data: " + req.responseText)
                                            accountSetup.error()
                                        }
                                    }
                                }
                            }
                            req.open("POST", "https://api.dropboxapi.com/2/users/get_current_account")
                            req.setRequestHeader("Authorization", "Bearer " + accountSetup.accessToken)
                            // Dummy body because dropbox doesn't seem to work without
                            req.setRequestHeader("Content-type", "application/json")
                            req.setRequestHeader("Content-length", 4)
                            req.send("null")
                        } else {
                            accountSetup.done()
                        }
                    } else if (status === Account.Invalid && accountSetup.hasSetName) {
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

                DropboxSettingsDisplay {
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
