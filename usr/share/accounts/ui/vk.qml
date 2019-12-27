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
            //: Error which is displayed when the user attempts to create a duplicate VK account
            //% "You have already added a VK account for user %1."
            var duplicateAccountError = qsTrId("jolla_settings_accounts_extensions-la-vk_duplicate_account").arg(root._existingUserName)
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
        //: The text explaining how user's VK data will be used on the device
        //% "When you add a VK account, information from this account will be added to the phone to provide a faster and better experience:<br><br> - Friends will be added to the People app and linked with existing contacts<br><br> - VK groups will be added to the Calendar app<br><br> - VK posts and notifications will be added to the Feeds view.<br><br> - Photos from VK will be available from the Gallery app<br><br>Some of this data will be cached to make it available when offline. This cache can be cleared by deleting the account.<br><br>Adding a VK account on your device means that you agree to VK's Terms of Service."
        legaleseText: qsTrId("jolla_settings_accounts_extensions-la-vk_consent_text")

        //: Button which the user presses to view VK Terms Of Service webpage
        //% "VKontakte Terms of Service"
        externalUrlText: qsTrId("jolla_settings_accounts_extensions-bt-vk_terms")
        externalUrlLink: "http://vk.com/terms"

        onStatusChanged: {
            if (status == PageStatus.Active && !_oauthPage) {
                _oauthPage = oAuthComponent.createObject(root)
                acceptDestination = _oauthPage
            }
        }

        onPageContainerChanged: {
            if (pageContainer == null && _oauthPage) {
                _oauthPage.cancelSignIn()
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
                    "Display": "touch",
                    "V": "5.21",
                    "ClientId": keyProvider.storedKey("vk", "vk-sync", "client_id"),
                    "ClientSecret": keyProvider.storedKey("vk", "vk-sync", "client_secret"),
                    "ResponseType": "token"
                }
                prepareAccountCreation(root.accountProvider, "vk-sync", sessionData)
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
            property int accountId
            property bool hasSetName

            signal done()
            signal error()

            property Account newAccount: Account {
                identifier: accountSetup.accountId
                onStatusChanged: {
                    if (status == Account.Initialized || status == Account.Synced) {
                        if (!accountSetup.hasSetName) {
                            getProfileInfo()
                        } else {
                            accountSetup.done()
                        }
                    } else if (status == Account.Invalid && accountSetup.hasSetName) {
                        accountSetup.error()
                    }
                }
            }

            function getProfileInfo() {
                var doc = new XMLHttpRequest()
                doc.onreadystatechange = function() {
                    if (doc.readyState === XMLHttpRequest.DONE) {
                        if (doc.status === 200) {
                            var users = JSON.parse(doc.responseText)
                            if (users.response.length > 0) {
                                var name = users.response[0].first_name
                                var lastName = users.response[0].last_name
                                if (name !== "" && lastName !== "") {
                                    name += " "
                                }
                                name += lastName

                                var screenName = users.response[0].screen_name
                                if (accountFactory.findAccount(
                                        "vk",
                                        "",
                                        "default_credentials_screen_name",
                                        screenName) !== 0) {
                                    // this account already exists. show error dialog.
                                    hasSetName = true
                                    root._existingUserName = name
                                    newAccount.remove()
                                    accountSetup.error()
                                    return
                                }

                                newAccount.setConfigurationValue("", "default_credentials_username", name)
                                newAccount.setConfigurationValue("", "default_credentials_screen_name", screenName)
                                newAccount.displayName = name
                                accountSetup.hasSetName = true
                                newAccount.sync()
                            } else {
                                console.log("Empty VK user query response")
                                accountSetup.done()
                            }
                        } else {
                            console.log("Failed to query VK users, error: " + doc.status)
                            accountSetup.done()
                        }
                    }
                }

                var postData = "access_token=" + accessToken
                var url = "https://api.vk.com/method/users.get?access_token="+accessToken+"&v=5.21&fields=screen_name"
                doc.open("GET", url)
                doc.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded')
                doc.send()
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

                VkSettingsDisplay {
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
