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
            //: Error which is displayed when the user attempts to create a duplicate Facebook account
            //% "You have already added a Facebook account for user %1."
            var duplicateAccountError = qsTrId("jolla_settings_accounts_extensions-la-facebook_duplicate_account").arg(root._existingUserName)
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
        //: The text explaining how user's Facebook data will be used on the device
        //% "When you add a Facebook account, information from this account will be added "
        //% "to the device to provide a faster and better experience:<br><br>"
        //% " - Facebook events will be added to the Calendar app<br><br>"
        //% " - Facebook photos will be available from the Gallery app, "
        //% "and you will be able to share photos on Facebook.<br><br>"
        //% "Some of this data will be cached to make it available when offline. "
        //% "This cache can be cleared at any time by disabling the relevant services "
        //% "on the account settings page.<br><br>"
        //% "Adding a Facebook account on your device means that you agree to "
        //% "Facebook's Terms of Service."
        legaleseText: qsTrId("jolla_settings_accounts_extensions-la-facebook_consent_text")

        //: Button which the user presses to view Facebook Terms Of Service webpage
        //% "Facebook Terms of Service"
        externalUrlText: qsTrId("jolla_settings_accounts_extensions-bt-facebook_terms")
        externalUrlLink: "https://m.facebook.com/legal/terms"

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
                    "Display": "popup",
                    "ClientId": keyProvider.storedKey("facebook", "facebook-sync", "client_id")
                }
                prepareAccountCreation(root.accountProvider, "facebook-sync", sessionData)
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
                            sni.arbitraryRequest(SocialNetwork.Get, "https://graph.facebook.com/v2.2/me?fields=name,id", queryItems)
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
                    var name = data["name"]
                    var fbid = data["id"]
                    if ((name == undefined || name == "") && (fbid == undefined || fbid == "")) {
                        accountSetup.done()
                    } else {
                        if (name != undefined && name != "") {
                            newAccount.setConfigurationValue("", "default_credentials_username", name)
                            newAccount.displayName = name
                            root._existingUserName = name
                        }
                        if (fbid != undefined && fbid != "") {
                            if (accountFactory.findAccount(
                                    "facebook",
                                    "",
                                    "facebook_id",
                                    fbid) !== 0) {
                                // this account already exists.  display error dialog.
                                accountSetup.hasSetName = true
                                newAccount.remove()
                                return
                            }
                            newAccount.setConfigurationValue("", "facebook_id", fbid)
                        }
                        accountSetup.hasSetName = true
                        newAccount.sync()
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

                FacebookSettingsDisplay {
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
