/*
 * Copyright (c) 2013 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0
import org.nemomobile.email 0.1

AccountCreationAgent {
    id: accountCreationAgent

    property Item settingsDialog
    property Item busyPageInstance
    property QtObject emailAccountInstance

    initialPage: Dialog {
        id: accountCreationDialog

        property string name: accountProvider.displayName
        property string iconSource: accountProvider.iconName
        property bool credentialsCreated
        property string defaultServiceName: accountProvider.serviceNames[0]
        property bool requiresAuthFields: settings.outgoingRequiresAuth ? settings.outgoingUsername != ""
                                                                                  && settings.outgoingPassword != "" : true
        property bool requiredFields: settings.emailAddress != "" && settings.incomingUsername != "" &&
                                      settings.incomingServer != "" && settings.incomingPort != "" &&
                                      requiresAuthFields && settings.outgoingServer != "" && settings.outgoingPort != ""
        property bool allFieldsEmpty: settings.emailAddress == "" && settings.incomingUsername == "" &&
                                      settings.incomingServer == "" && settings.incomingPort == "" &&
                                      settings.outgoingUsername == "" && settings.outgoingServer == "" &&
                                      settings.outgoingPort == "" && autoDiscoverySettings.emailAddress == "" &&
                                      autoDiscoverySettings.password == ""
        property bool initialSetup: true
        property bool initialSetupRequiredFields: autoDiscoverySettings.emailAddress != "" && autoDiscoverySettings.password != ""
        property bool showSettings
        property bool checkCredentials
        property bool checkMandatoryFields
        property bool showSettingsDiscoveryError

        acceptDestinationAction: PageStackAction.Push
        canAccept: initialSetup ? initialSetupRequiredFields : requiredFields
        onAccepted: initialSetup ? busyPageInstance : _saveSettings()
        onRejected: _discard()

        function acceptInitialSetup() {
            _setInitialSetupSettings()
            emailAccountInstance.retrieveSettings(autoDiscoverySettings.emailAddress)
        }

        function _discard() {
            if (account.status < Account.Error) {
                account.remove()
            }
        }

        function _saveSettings() {
            account.displayName = settings.incomingUsername

            account.setConfigurationValue("", "default_credentials_username", settings.incomingUsername)

            //change to username depending on the design
            account.setConfigurationValue(defaultServiceName, "emailaddress", settings.emailAddress)

            //this should go to the service file
            account.setConfigurationValue(defaultServiceName, "type", "8")

            account.setConfigurationValue(defaultServiceName, "credentialsCheck", 1)

            if (settings.serverTypeIndex == 0) {
                account.setConfigurationValue(defaultServiceName, "incomingServerType", 0)
                account.setConfigurationValue(defaultServiceName, "imap4/username", settings.incomingUsername)
                account.setConfigurationValue(defaultServiceName, "imap4/server", settings.incomingServer)
                account.setConfigurationValue(defaultServiceName, "imap4/port", settings.incomingPort)
                account.setConfigurationValue(defaultServiceName, "imap4/encryption", settings.incomingSecureConnectionIndex)
                account.setConfigurationValue(defaultServiceName, "imap4/pushCapable", 0)
                account.setConfigurationValue(defaultServiceName, "imap4/checkInterval", 0)
                account.setConfigurationValue(defaultServiceName, "imap4/downloadAttachments", 0)
                account.setConfigurationValue(defaultServiceName, "imap4/servicetype", "source")
                account.setConfigurationValue(defaultServiceName, "imap4/acceptUntrustedCertificates", settings.acceptUntrustedCertificates ? 1 : 0)
            } else {
                account.setConfigurationValue(defaultServiceName, "incomingServerType", 1)
                account.setConfigurationValue(defaultServiceName, "customFields/showMoreMails", "false")
                account.setConfigurationValue(defaultServiceName, "pop3/username", settings.incomingUsername)
                account.setConfigurationValue(defaultServiceName, "pop3/server", settings.incomingServer)
                account.setConfigurationValue(defaultServiceName, "pop3/port", settings.incomingPort)
                account.setConfigurationValue(defaultServiceName, "pop3/encryption", settings.incomingSecureConnectionIndex)
                account.setConfigurationValue(defaultServiceName, "pop3/servicetype", "source")
                account.setConfigurationValue(defaultServiceName, "pop3/autoDownload", 1)
                account.setConfigurationValue(defaultServiceName, "pop3/acceptUntrustedCertificates", settings.acceptUntrustedCertificates ? 1 : 0)
            }
            account.setConfigurationValue(defaultServiceName, "smtp/smtpusername", settings.outgoingUsername)
            //change to username depending on the design
            account.setConfigurationValue(defaultServiceName, "smtp/address", settings.emailAddress)
            account.setConfigurationValue(defaultServiceName, "smtp/server", settings.outgoingServer)
            account.setConfigurationValue(defaultServiceName, "smtp/port", settings.outgoingPort)
            account.setConfigurationValue(defaultServiceName, "smtp/encryption", settings.outgoingSecureConnectionIndex)
            // If auth is required set authFromCapabilities to true, if not set to false and also set authentication to 0
            if (!settings.outgoingRequiresAuth) {
                account.setConfigurationValue(defaultServiceName, "smtp/authentication", 0)
            }
            account.setConfigurationValue(defaultServiceName, "smtp/authFromCapabilities", settings.outgoingRequiresAuth ? 1 : 0)
            account.setConfigurationValue(defaultServiceName, "smtp/servicetype", "sink")
            account.setConfigurationValue(defaultServiceName, "smtp/acceptUntrustedCertificates", settings.acceptUntrustedCertificates ? 1 : 0)

            //required to test configuration
            checkCredentials = true
            account.enableWithService(defaultServiceName)
            account.sync()

            accountCreationDialog.acceptDestination = accountCreationAgent.busyPageInstance
            accountCreationDialog.acceptDestinationInstance.currentTask = "checkCredentials"
        }

        function _setInitialSetupSettings() {
            settings.emailAddress = autoDiscoverySettings.emailAddress
            settings.incomingUsername = autoDiscoverySettings.emailAddress
            settings.outgoingUsername = autoDiscoverySettings.emailAddress
            settings.incomingPassword = autoDiscoverySettings.password
            settings.outgoingPassword = autoDiscoverySettings.password
        }

        function _taskSucceeded() {
            if (accountCreationAgent.busyPageInstance !== null) {
                accountCreationAgent.busyPageInstance.operationSucceeded()
            }
        }

        function _taskFailed(serverType, error) {
            if (accountCreationAgent.busyPageInstance !== null) {
                accountCreationAgent.busyPageInstance.operationFailed(serverType, error)
            }
        }

        onAcceptPendingChanged: {
            if (acceptPending === true) {
                checkMandatoryFields = true
                root.focus = true
            }
        }

        onStatusChanged: {
            if (status === PageStatus.Active && account.identifier === 0) {
                accountManager.createAccount(accountProvider.name)
                accountCreationAgent.busyPageInstance = busyPageComponent.createObject(accountCreationAgent)
                accountCreationDialog.acceptDestination = accountCreationAgent.busyPageInstance
                accountCreationDialog.acceptDestinationInstance.currentTask = "settingsDiscovery"
                emailAccountInstance = emailAccountComponent.createObject(accountCreationAgent)
            }
        }

        SilicaFlickable {
            id: flickable

            anchors.fill: parent
            contentHeight: Math.max(contentColumn.height + (manualSetupButton.visible ? manualSetupButton.height : 0), parent.height)

            Column {
                id: contentColumn

                width: parent.width

                DialogHeader {
                    dialog: accountCreationDialog

                    // Ensure checkMandatoryFields is set if 'accept' is tapped and some fields
                    // are not valid
                    Item {
                        id: headerChild
                        Connections {
                            target: headerChild.parent
                            onClicked: accountCreationDialog.checkMandatoryFields = true
                        }
                    }
                }

                Item {
                    x: Theme.horizontalPageMargin
                    width: parent.width - x*2
                    height: icon.height + Theme.paddingLarge

                    Image {
                        id: icon
                        width: Theme.iconSizeLarge
                        height: width
                        anchors.top: parent.top
                        source: accountCreationDialog.iconSource
                    }
                    Label {
                        anchors {
                            left: icon.right
                            leftMargin: Theme.paddingLarge
                            right: parent.right
                            verticalCenter: icon.verticalCenter
                        }
                        text: accountCreationDialog.name
                        color: Theme.highlightColor
                        font.pixelSize: Theme.fontSizeLarge
                        truncationMode: TruncationMode.Fade
                    }
                }

                Label {
                    id: settingsDiscoveryFailedLabel
                    x: Theme.horizontalPageMargin
                    visible: accountCreationDialog.showSettingsDiscoveryError
                    width: parent.width - x*2
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.highlightColor
                    //: Information label displayed when settings for this account could not be discovered
                    //% "Couldn't find the settings for your account. Please complete the settings in the fields below."
                    text: qsTrId("components_accounts-la-genericemail_settings_discovery_failed")
                }

                Column {
                    id: autoDiscoverySettings
                    visible: !accountCreationDialog.showSettings
                    property alias emailAddress: emailAddress.text
                    property alias password: password.text

                    width: parent.width

                    GeneralEmailAddressField {
                        id: emailAddress
                        width: parent.width
                        errorHighlight: !text && accountCreationDialog.checkMandatoryFields
                        EnterKey.iconSource: "image://theme/icon-m-enter-next"
                        EnterKey.onClicked: password.focus = true
                    }

                    PasswordField {
                        id: password
                        errorHighlight: !text && accountCreationDialog.checkMandatoryFields
                        EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                        EnterKey.onClicked: autoDiscoverySettings.focus = true
                    }
                }

                EmailCommon {
                    id: settings
                    visible: accountCreationDialog.showSettings
                    checkMandatoryFields: accountCreationDialog.checkMandatoryFields
                    // Fade for manual setup transition
                    opacity: accountCreationDialog.initialSetup ? 0 : 1

                    Behavior on opacity { FadeAnimation {} }
                }
            }

            Button {
                id: manualSetupButton
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.max(contentColumn.height + Theme.paddingLarge, flickable.height - height - Theme.paddingLarge)
                        + pageStack.panelSize   // don't move button when vkb is open
                visible: !accountCreationDialog.showSettings

                //: Manual configuration button
                //% "Manual setup"
                text: qsTrId("components_accounts-la-manual_setup")
                onClicked: {
                    // Required to close vkb
                    accountCreationDialog.focus = true
                    accountCreationDialog._setInitialSetupSettings()
                    accountCreationDialog.showSettings = true
                    accountCreationDialog.initialSetup = false
                }
            }

            VerticalScrollDecorator {}
        }
    }

    Connections {
        target: accountCreationAgent.accountManager

        // Trigger account transition to 'Initialized' status
        onAccountCreated: {
            account.identifier = accountId
        }
    }

    Component {
        id: busyPageComponent
        EmailBusyPage {
            settingsDialog: accountCreationAgent.settingsDialog

            onStatusChanged: {
                if (status === PageStatus.Active) {
                    if (currentTask == "settingsDiscovery") {
                        accountCreationDialog.acceptInitialSetup()
                    }
                }
            }

            onCurrentTaskChanged: state = "busy"

            onInfoButtonClicked: {
                skipping = true
                if (hideIncomingSettings) {
                    // we are in saved mode, skip smtp creation only
                    settingsDialog.skipSmtp = true
                    pageStack.animatorReplace(settingsDialog)
                } else {
                    // we are in skip mode, so remove the account
                    account.remove()
                    accountCreationAgent.goToEndDestination()
                }
            }

            onPageContainerChanged: {
                if (pageContainer == null && !skipping) {
                    accountCreationDialog.focus = true

                    if (currentTask == "checkCredentials" && errorOccured) {
                        if (hideIncomingSettings) {
                            settings.hideIncoming = true
                        }
                        // Reset everything
                        emailAccountInstance.cancelTest()
                        account.remove()
                        accountCreationDialog.credentialsCreated = false
                        account.incomingCredentialsCreated = false
                        account.outgoingCredentialsCreated = false
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

        property bool incomingCredentialsCreated
        property bool outgoingCredentialsCreated

        onStatusChanged: {
            if (status === Account.Synced) {
                if (!incomingCredentialsCreated) {
                    incomingCredentialsCreated = true
                    var credentialsName = (settings.serverTypeIndex == 0) ? "imap4/CredentialsId": "pop3/CredentialsId"
                    account.createSignInCredentials( "Jolla", credentialsName,
                                account.signInParameters(accountCreationDialog.defaultServiceName, settings.incomingUsername, settings.incomingPassword))
                }
                // set the accountId for the settings page
                if (accountCreationDialog.credentialsCreated) {
                    accountCreationAgent.accountCreated(identifier)
                    if (accountCreationDialog.checkCredentials) {
                        accountCreationAgent.accountCreated(identifier)
                        accountSyncManager.createProfile("syncemail", identifier, "email")
                        emailAccountInstance.accountId = identifier
                        // Create settings page
                        accountCreationAgent.settingsDialog = settingsComponent.createObject(accountCreationAgent, {"accountId": identifier, "isNewAccount": true})
                        // 120 seconds timeout
                        emailAccountInstance.test(120)
                        accountCreationDialog.showSettingsDiscoveryError = false
                        accountCreationDialog.checkCredentials = false
                    }
                }
            } else if (status === Account.Error) {
                console.log("Generic email provider account error:", errorMessage)
                accountCreationAgent.accountCreationError(errorMessage)
            }
        }

        onSignInCredentialsCreated: {
            if (!outgoingCredentialsCreated) {
                outgoingCredentialsCreated = true
                account.createSignInCredentials( "Jolla", "smtp/CredentialsId",
                            account.signInParameters(accountCreationDialog.defaultServiceName, settings.outgoingUsername, settings.outgoingPassword))
            } else {
                accountCreationDialog.credentialsCreated = true
                var serviceSettings = account.configurationValues("")
                account.setConfigurationValue(accountCreationDialog.defaultServiceName, "smtp/CredentialsId", serviceSettings["Jolla/segregated_credentials/smtp/CredentialsId"])
                var credentialsName = (settings.serverTypeIndex == 0) ? "imap4/CredentialsId": "pop3/CredentialsId"
                account.setConfigurationValue(accountCreationDialog.defaultServiceName, credentialsName, serviceSettings["Jolla/segregated_credentials/" + credentialsName])
                // Enabling account here for credentials checking
                account.enabled = true
                account.sync()
            }
        }

        onSignInError: {
            console.log("Generic email provider account error:", message)
            accountCreationAgent.accountCreationError(message)
            account.remove()
        }
    }

    Component {
        id: emailAccountComponent
        EmailAccount {
            id: emailAccount

            onTestSucceeded: {
                settingsDialog.pushCapable = emailAccount.pushCapable
                accountCreationDialog._taskSucceeded()
            }

            onTestFailed: {
                accountCreationDialog._taskFailed(serverType, error)
            }

            onSettingsRetrieved: {
                settings.serverTypeIndex = emailAccount.recvType == "imap4" ? 0 : 1
                settings.incomingServer = emailAccount.recvServer
                settings.incomingPort = emailAccount.recvPort
                settings.incomingSecureConnectionIndex = parseInt(emailAccount.recvSecurity)

                settings.outgoingServer = emailAccount.sendServer
                settings.outgoingPort = emailAccount.sendPort
                settings.outgoingSecureConnectionIndex = parseInt(emailAccount.sendSecurity)
                // 0 means no auth
                settings.outgoingRequiresAuth = parseInt(emailAccount.sendAuth)

                accountCreationAgent.busyPageInstance.settingsRetrieved = true
                accountCreationDialog.showSettings = true
                accountCreationDialog.initialSetup = false
                accountCreationDialog._saveSettings()
            }

            onSettingsRetrievalFailed: {
                accountCreationDialog.showSettingsDiscoveryError = true
                accountCreationDialog.showSettings = true
                // Don't emit error here, just show manual config page
                accountCreationDialog._taskSucceeded()
                accountCreationDialog.initialSetup = false
            }
        }
    }

    AccountSyncManager {
        id: accountSyncManager
    }

    Component {
        id: settingsComponent
        Dialog {
            property alias isNewAccount: settingsDisplay.isNewAccount
            property alias accountId: settingsDisplay.accountId
            property alias skipSmtp: settingsDisplay.skipSmtp
            property alias pushCapable: settingsDisplay.pushCapable

            acceptDestination: accountCreationAgent.endDestination
            acceptDestinationAction: accountCreationAgent.endDestinationAction
            acceptDestinationProperties: accountCreationAgent.endDestinationProperties
            acceptDestinationReplaceTarget: accountCreationAgent.endDestinationReplaceTarget
            backNavigation: false

            onAccepted: {
                accountCreationAgent.delayDeletion = true
                settingsDisplay.saveNewAccount()
            }

            Component.onDestruction: {
                if (status == PageStatus.Active) {
                    // app closed while setup is in progress, remove account
                    account.remove()
                }
            }

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: header.height + settingsDisplay.height + Theme.paddingLarge

                DialogHeader {
                    id: header
                }

                EmailSettingsDisplay {
                    id: settingsDisplay
                    anchors.top: header.bottom
                    accountManager: accountCreationAgent.accountManager
                    accountProvider: accountCreationAgent.accountProvider
                    autoEnableAccount: true
                    settings: settings

                    onAccountSaveCompleted: {
                        accountCreationAgent.delayDeletion = false
                    }
                }
                VerticalScrollDecorator {}
            }
        }
    }
}
