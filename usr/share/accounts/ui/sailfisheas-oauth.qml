/*
 * Copyright (C) 2022 Jolla Ltd.
 *
 * License: Proprietary
 */
import QtQuick 2.0
import QtQml 2.2
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0
import com.jolla.sailfisheas 1.0
import Nemo.Connectivity 1.0
import "SailfishEasSettings.js" as ServiceSettings

AccountCreationAgent {
    id: accountCreationAgent

    property Item _oauthPage
    property Item busyPageInstance
    property Item settingsDialog

    StoredKeyProvider {
        id: keyProvider

        function clientId() {
            return keyProvider.storedKey("sailfisheas", "", "client_id")
        }
    }

    Component {
        id: oAuthComponent
        OAuthAccountSetupPage {
            function getEmailFromIdToken(token) {
                // Note that this does not attempt to check the signature
                // Split payload
                var sep1 = token.indexOf('.')
                var sep2 = token.indexOf('.', sep1 + 1)
                var payload = token.substring(sep1, sep2)
                // Replace a few characters to convert from base64url to normal base64
                // See also https://stackoverflow.com/a/51838635
                payload = payload.replace(/-/g, '+').replace(/_/g, '/')
                // and also determine padding to add
                var padding = payload.length % 4
                if (padding > 1) {
                    // If padding length was 1, the encoded string would be invalid
                    payload += new Array(5 - padding).join('=')
                }
                // Now decode with regular base64 decoder
                payload = Qt.atob(payload)
                var content = JSON.parse(payload)
                return content["email"] || ""
            }

            Component.onCompleted: {
                var sessionData = {
                    "ClientId": keyProvider.clientId(),
                    "Scope": ["https://outlook.office.com/.default", "offline_access", "openid", "email"],
                    "ExtraParams": {
                        "prompt": "select_account" // Ask to select account
                    }
                }
                prepareAccountCreation(accountCreationAgent.accountProvider, "sailfisheas-oauth-email", sessionData)
            }
            onAccountCreated: {
                var idToken = responseData["IdToken"]
                if (idToken !== undefined) {
                    settings.emailaddress = getEmailFromIdToken(idToken)
                }
                var accessToken = responseData["AccessToken"]
                account.identifier = accountId
                pageStack.replace(accountCreationDialog, { "accessToken": accessToken })
            }
            onAccountCreationError: {
                accountCreationAgent.accountCreationError(errorMessage)
            }
        }
    }

    initialPage: AccountCreationLegaleseDialog {
        //% "Adding a Microsoft 365 account on your device means that you agree to Microsoft 365's Terms of Service."
        legaleseText: qsTrId("components_accounts-la-microsoft_365_consent_text")

        //: Button which the user presses to view Microsoft 365 Terms Of Service webpage
        //% "Microsoft 365 Terms of Service"
        externalUrlText: qsTrId("components_accounts-bt-microsoft_365_terms")
        externalUrlLink: "https://www.microsoft.com/en-us/servicesagreement/"

        acceptDestinationAction: PageStackAction.Push
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

    ConnectionHelper {
        id: connectionHelper

        onOnlineChanged: {
            if (online && accountCreationDialog.delayTask) {
                delayedTask()
            }
        }

        function delayedTask() {
            accountCreationDialog.delayTask = false
            if (connectionHelper.online) {
                accountCreationAgent.busyPageInstance.runAccountCreation()
            } else {
                if (accountCreationAgent.busyPageInstance.currentTask === "checkCredentials") {
                    ServiceSettings.saveConnectionSettings(settings, "sailfisheas-oauth")
                    account.displayName = settings.emailaddress
                    account.sync()
                } else {
                    accountCreationAgent.busyPageInstance.cancelAccountCreation()
                }
            }
        }

        Component.onCompleted: {
            connectionHelper.requestNetwork()
        }
    }

    Dialog {
        id: accountCreationDialog

        property string accessToken // For autodiscovery
        property string defaultServiceName: accountProvider.serviceNames[0]
        property bool _serverAddressRequired: showManualSettings ? settings.server != "" : true
        property bool _knownCredentials: accDbCheckService.knownEmail(settings.emailaddress) ||
                                        accDbCheckService.alreadyCreated(settings.username, settings.server, settings.domain)
        property bool showManualSettings
        property bool showSettingsDiscoveryError
        property bool delayTask

        acceptDestinationAction: PageStackAction.Push
        canAccept: settings.emailaddress != "" && _serverAddressRequired && !_knownCredentials
        onRejected: {
            if (account.status < Account.Error) {
                account.remove()
            }
        }

        onAcceptBlocked: settings.checkMandatoryFields = true

        onShowManualSettingsChanged: {
            if (status === PageStatus.Active) {
                accountCreationAgent.busyPageInstance.currentTask = showManualSettings ? "checkCredentials" : "autodiscovery"
            }
        }

        function acceptInitialSetup() {
            autoDiscoveryService.startAutoDiscoveryOAuth(settings.emailaddress, accessToken)
        }

        function save() {
            ServiceSettings.saveConnectionSettings(settings, "sailfisheas-oauth")
            account.displayName = settings.emailaddress
            account.sync()
        }

        function taskFailed(error) {
            // force main page to show all connection settings
            accountCreationDialog.showManualSettings = true
            if (accountCreationAgent.busyPageInstance !== null) {
                accountCreationAgent.busyPageInstance.operationFailed(error)
            }
        }

        onStatusChanged: {
            if (status === PageStatus.Active) {
                accountCreationAgent.busyPageInstance = busyPageComponent.createObject(accountCreationAgent)
                accountCreationDialog.acceptDestination = accountCreationAgent.busyPageInstance
                accountCreationAgent.busyPageInstance.currentTask = showManualSettings ? "checkCredentials" : "autodiscovery"
            }
        }

        SilicaFlickable {
            anchors.fill: parent
            contentHeight: contentColumn.height + detailsButton.height + 2*Theme.paddingLarge

            Column {
                id: contentColumn
                width: parent.width

                DialogHeader {
                    dialog: accountCreationDialog
                }

                Item {
                    x: Theme.paddingLarge
                    width: parent.width - x*2
                    height: icon.height + Theme.paddingLarge

                    Image {
                        id: icon
                        width: Theme.iconSizeLarge
                        height: width
                        anchors.top: parent.top
                        source: accountProvider.iconName
                    }
                    Label {
                        anchors {
                            left: icon.right
                            leftMargin: Theme.paddingLarge
                            right: parent.right
                            verticalCenter: icon.verticalCenter
                        }
                        text: accountProvider.displayName
                        color: Theme.highlightColor
                        font.pixelSize: Theme.fontSizeLarge
                        truncationMode: TruncationMode.Fade
                    }
                }

                Label {
                    x: Theme.paddingLarge
                    visible: opacity > 0.0
                    opacity: accountCreationDialog._knownCredentials ? 1.0 : 0.0
                    height: opacity * implicitHeight
                    Behavior on opacity { FadeAnimation{} }
                    width: parent.width - x*2
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.highlightColor
                    //: Information label displayed when settings entered for this account are used in another configured one
                    //% "Account for entered credentials already exists."
                    text: qsTrId("components_accounts-la-activesync_settings_already_exists")
                }

                Label {
                    x: Theme.paddingLarge
                    visible: opacity > 0.0
                    opacity: (accountCreationDialog.showSettingsDiscoveryError
                              && !accountCreationDialog._knownCredentials) ? 1.0 : 0.0
                    height: opacity * implicitHeight
                    Behavior on opacity { FadeAnimation{} }
                    width: parent.width - x*2
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.highlightColor
                    //: Information label displayed when settings for this account could not be discovered
                    //% "Couldn't find the settings for your account. Please complete the settings in the fields below."
                    text: qsTrId("components_accounts-la-activesync_settings_discovery_failed")
                }

                SailfishEasConnectionSettings {
                    id: settings
                    oauthEnabled: true
                    editMode: accountCreationDialog.showManualSettings
                    onCertificateDataSaved: {
                        ServiceSettings.saveConnectionSettings(settings, "sailfisheas-oauth")
                        console.log("certificate data saved with id", sslCredentialsId)
                        account.finishCheckCredentials = true
                        account.sync()
                    }
                }
            }

            Button {
                id: detailsButton
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: contentColumn.bottom
                    topMargin: Theme.paddingLarge
                }
                //% "Less"
                text: accountCreationDialog.showManualSettings ? qsTrId("components_accounts-bt-activesync_less")
                                                                 //% "More"
                                                               : qsTrId("components_accounts-bt-activesync_more")
                onClicked: {
                    accountCreationDialog.showManualSettings = !accountCreationDialog.showManualSettings
                    accountCreationDialog.focus = true
                }
            }

            VerticalScrollDecorator {}
        }
    }

    CheckExistence {
        id: accDbCheckService
    }

    AutoDiscovery {
        id: autoDiscoveryService
        onAutoDiscoveryDone: {
            console.log("[jsa-eas] AutoDiscovery DONE: server == " + autoDiscoveryService.server)
            settings.server = autoDiscoveryService.server
            settings.port = autoDiscoveryService.port
            settings.secureConnection = autoDiscoveryService.secureConnection
            settings.username = autoDiscoveryService.userName
            settings.domain = autoDiscoveryService.domain
            accountCreationAgent.busyPageInstance.settingsRetrieved = true
            accountCreationAgent.busyPageInstance.operationSucceeded()
            accountCreationDialog.save()
        }
        onAutoDiscoveryFailed: {
            console.log("[jsa-eas] AutoDiscovery FAILED: error == " + error)
            accountCreationAgent.busyPageInstance.settingsRetrieved = false
            accountCreationDialog.showSettingsDiscoveryError = true
            accountCreationDialog.showManualSettings = true
            // Don't emit error here, just show manual config page
            accountCreationAgent.busyPageInstance.operationSucceeded()
        }
    }

    CheckCredentials {
        id: checkCredentialsService

        function finishCredentials() {
            var component = Qt.createComponent(Qt.resolvedUrl("SailfishEasSettingsDialog.qml"))
            if (component.status === Component.Ready) {
                accountCreationAgent.settingsDialog = component.createObject(accountCreationAgent,
                                                                             {
                                                                                 "accountId": account.identifier,
                                                                                 "connectionSettings": settings,
                                                                                 "oauthEnabled": true
                                                                             })
                accountCreationAgent.busyPageInstance.operationSucceeded()
            } else {
                console.log(component.errorString())
            }
        }

        onCheckCredentialsDone: {
            console.log("[jsa-eas] Credentials OK!")
            // create the settings dialog after certificate data is handled too
            if (settings.hasSslCertificate) {
                settings.storeCertificateData()
            } else {
                finishCredentials()
            }
            account.credentialsChecked = true
        }
        onCheckCredentialsFailed: {
            console.log("[jsa-eas] Credentials check FAILED: error == " + error)
            if (error === CheckCredentials.CHECKCREDENTIALS_ERROR_SLL_HANDSHAKE) {
                accountCreationDialog.taskFailed("SSL failed")
            } else if (error !== CheckCredentials.CHECKCREDENTIALS_ERROR_CANCELED) {
                accountCreationDialog.taskFailed("CC failed")
            }
        }
    }

    Component {
        id: busyPageComponent
        SailfishEasBusyPage {
            property bool _skipping
            property bool settingsRetrieved
            backNavigation: (state == "info") || accountCreationDialog.delayTask

            function operationSucceeded() {
                _errorOccured = false
                if (currentTask === "checkCredentials") {
                    pageStack.animatorReplace(settingsDialog)
                    currentTask = "creatingAccount"
                } else if (currentTask === "autodiscovery") {
                    if (settingsRetrieved) {
                        currentTask = "checkCredentials"
                    } else {
                        pageStack.pop()
                    }
                } else if (currentTask === "checkProvisioning") {
                    accountCreationAgent.goToEndDestination()
                }
            }

            function runAccountCreation() {
                if (currentTask === "autodiscovery") {
                    accountCreationDialog.acceptInitialSetup()
                } else if (currentTask === "checkCredentials") {
                    accountCreationDialog.save()
                } else if (currentTask === "checkProvisioning") {
                    settingsDialog.accountSaveSync()
                } else if (currentTask === "savingAccount") {
                    settingsDialog.accountSaveSync()
                    accountCreationAgent.goToEndDestination()
                }
            }

            function cancelAccountCreation() {
                accountCreationAgent.busyPageInstance.settingsRetrieved = false
                accountCreationDialog.showSettingsDiscoveryError = true
                // Don't emit error here, just show manual config page
                accountCreationAgent.busyPageInstance.operationSucceeded()
            }

            onStatusChanged: {
                if (status === PageStatus.Active) {
                    if (connectionHelper.online) {
                        runAccountCreation()
                    } else {
                        accountCreationDialog.delayTask = true
                        connectionHelper.attemptToConnectNetwork()
                    }
                } else if (status === PageStatus.Inactive) {
                    accountCreationDialog.delayTask = false
                }
            }

            onInfoButtonClicked: {
                _skipping = true
                // we are in skip mode, so remove the account
                account.remove()
                accountCreationAgent.goToEndDestination()
            }

            onPageContainerChanged: {
                if (pageContainer == null && !_skipping) {
                    accountCreationDialog.focus = true

                    if (currentTask == "checkCredentials" && _errorOccured) {
                        // We are coming back from check credentials error
                        // Reset everything
                        accountCreationDialog.showSettingsDiscoveryError = false
                        accountCreationDialog.showManualSettings = true
                    } else if (currentTask == "checkProvisioning" && _errorOccured) {
                        state = "busy"
                    }
                }
            }

            Component.onDestruction: {
                if (status == PageStatus.Active) {
                    // app closed while setup is in progress, remove account
                    account.remove()
                }
            }
        }
    }

    Account {
        id: account

        property bool finishCheckCredentials
        property bool incomingCredentialsCreated
        property bool credentialsChecked
        property string _accessToken // For repeated credentials check

        onStatusChanged: {
            if (status === Account.Synced) {
                if (finishCheckCredentials) {
                    console.log("finishing credentials from account")
                    finishCheckCredentials = false
                    checkCredentialsService.finishCredentials()
                } else if (!incomingCredentialsCreated) {
                    console.log("creating sign in credentials for account")
                    incomingCredentialsCreated = true
                    var params = account.signInParameters(accountCreationDialog.defaultServiceName)
                    params.setParameter("ClientId", keyProvider.clientId());
                    account.createSignInCredentials("Jolla", "ActiveSync", params)
                } else if (!credentialsChecked && _accessToken !== "") {
                    console.log("checking credentials for account")
                    checkCredentials()
                } else {
                    console.log("create profiles for account")
                    accountSyncManager.createProfile("sailfisheas.Email", identifier, "sailfisheas-oauth-email")
                    accountSyncManager.createProfile("sailfisheas.Calendars", identifier, "sailfisheas-oauth-calendars")
                    accountSyncManager.createProfile("sailfisheas.Contacts", identifier, "sailfisheas-oauth-contacts")
                }
            } else if (status === Account.Error) {
                console.log("ActiveSync provider account error:", errorMessage)
                accountCreationAgent.accountCreationError(errorMessage)
            }
        }

        function checkCredentials() {
            if (settings.hasSslCertificate) {
                checkCredentialsService.checkOAuthCredentials(_accessToken, settings.server, settings.port,
                                                              settings.secureConnection, settings.acceptSSLCertificates,
                                                              settings.sslCertificatePath, settings.sslCertificatePassword)
            } else {
                checkCredentialsService.checkOAuthCredentials(_accessToken, settings.server, settings.port,
                                                              settings.secureConnection, settings.acceptSSLCertificates)
            }
        }

        onSignInCredentialsCreated: {
            accountCreationAgent.accountCreated(account.identifier)
            _accessToken = data["AccessToken"]
            checkCredentials()
        }

        onSignInError: {
            console.log("ActiveSync provider account error:", message)
            accountCreationAgent.accountCreationError(message)
            account.remove()
        }
    }

    AccountSyncManager {
        id: accountSyncManager
    }
}
