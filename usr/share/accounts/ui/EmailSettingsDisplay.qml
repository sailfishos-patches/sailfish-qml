import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0
import org.nemomobile.configuration 1.0
import org.nemomobile.systemsettings 1.0

Column {
    id: root

    property string _defaultServiceName: "email"
    property bool _saving
    property bool _syncProfileWhenAccountSaved
    property alias accountEnabled: mainAccountSettings.accountEnabled
    property bool autoEnableAccount
    property bool skipSmtp
    property bool isNewAccount
    property bool pushCapable
    property bool accountIsReadOnly
    property bool accountIsProvisioned
    property string outgoingUsername
    property string incomingUsername

    property Provider accountProvider
    property AccountManager accountManager
    property alias account: account
    property int accountId

    property QtObject _emailSyncOptions
    property var _emailSyncProfileIds: []
    property AccountSyncManager _syncManager: AccountSyncManager {}
    property Item settings

    signal accountSaveCompleted(var success)

    function saveAccount(blockingSave, saveSettings) {
        account.enabled = mainAccountSettings.accountEnabled
        account.displayName = mainAccountSettings.accountDisplayName
        account.enableWithService(_defaultServiceName)
        _saveEmailDetails()

        if (settingsLoader.anySyncOptionsModified() || _emailSyncOptions.modified) {
            _updateProfiles(_emailSyncProfileIds, {}, _emailSyncOptions)
        }

        if (saveSettings) {
            saveServiceSettings()
        }

        _saving = true
        if (blockingSave) {
            account.blockingSync()
        } else {
            account.sync()
        }
    }

    function saveNewAccount() {
        account.displayName = mainAccountSettings.accountDisplayName
        account.enabled = mainAccountSettings.accountEnabled
        account.setConfigurationValue(_defaultServiceName, "credentialsCheck", 0)
        account.setConfigurationValue(_defaultServiceName, "syncemail/profile_id", _emailSyncProfileIds[0])
        if (skipSmtp) {
            account.setConfigurationValue(_defaultServiceName, "canTransmit", 0)
            account.setConfigurationValue(_defaultServiceName, "smtp/smtpusername", "")
            account.setConfigurationValue(_defaultServiceName, "smtp/address", "")
            account.setConfigurationValue(_defaultServiceName, "smtp/server", "")
            account.setConfigurationValue(_defaultServiceName, "smtp/port", 0)
            account.setConfigurationValue(_defaultServiceName, "smtp/servicetype", "")
            account.setConfigurationValue(_defaultServiceName, "smtp/CredentialsId", 0)

            account.removeSignInCredentials("Jolla", "smtp/CredentialsId")
        }

        _updateProfiles(_emailSyncProfileIds, {}, _emailSyncOptions)
        _saveEmailDetails()
        root._syncProfileWhenAccountSaved = true
        account.sync()
    }

    function saveAccountAndSync(saveSettings) {
        root._syncProfileWhenAccountSaved = true
        saveAccount(false, saveSettings)
    }

    function _updateProfiles(profileIds, props, syncOptions) {
        if (syncOptions !== null) {
            for (var i=0; i<profileIds.length; i++) {
                _syncManager.updateProfile(profileIds[i], props, syncOptions)
            }
        }
    }

    function _populateEmailDetails() {
        var serviceSettings = account.configurationValues(_defaultServiceName)
        var signature = serviceSettings["signature"]
        if (signature) {
            signatureField.text = signature
        }
        signatureEnabledSwitch.checked = serviceSettings["signatureEnabled"]
        var fullName = serviceSettings["fullName"]
        if (fullName) {
            yourNameField.text = fullName
        }
        var email = serviceSettings["emailaddress"]
        if (email) {
            cryptoSection.emailAddress = email
        }
        if (serviceSettings["crypto/signByDefault"]) {
            var ids = serviceSettings["crypto/keyNames"]
            if (ids && ids.length > 0) {
                // UI is only working for the first key in a multi-sign setting.
                cryptoSection.defaultKey = ids[0]
            }
        }
    }

    function _saveEmailDetails() {
        account.setConfigurationValue(_defaultServiceName, "signatureEnabled", signatureEnabledSwitch.checked)
        account.setConfigurationValue(_defaultServiceName, "signature", signatureField.text)
        account.setConfigurationValue(_defaultServiceName, "fullName", yourNameField.text)

        // check if is push capable and add default folder (Inbox)
        if (pushCapable) {
            account.setConfigurationValue(_defaultServiceName, "imap4/pushFolders", "INBOX")
        }
        if (cryptoSection.keyIdentifier.length > 0
            && cryptoSection.pluginName.length > 0) {
            account.setConfigurationValue(_defaultServiceName, "crypto/signByDefault", true)
            account.setConfigurationValue(_defaultServiceName, "crypto/pluginName", cryptoSection.pluginName)
            var serviceSettings = account.configurationValues(_defaultServiceName)
            var ids = serviceSettings["crypto/keyNames"]
            if (ids && ids.length > 0) {
                // UI is only working for the first key in a multi-sign setting.
                ids[0] = cryptoSection.keyIdentifier
                account.setConfigurationValue(_defaultServiceName, "crypto/keyNames", ids)
            } else {
                account.setConfigurationValue(_defaultServiceName, "crypto/keyNames", [cryptoSection.keyIdentifier])
            }
        } else {
            account.setConfigurationValue(_defaultServiceName, "crypto/signByDefault", false)
        }
    }

    function populateServiceSettings() {
        var serviceSettings = account.configurationValues(_defaultServiceName)
        settings.emailAddress = serviceSettings["emailaddress"]
        settings.serverTypeIndex = parseInt(serviceSettings["incomingServerType"])
        if (settings.serverTypeIndex == 0) {
            settings.incomingUsername = serviceSettings["imap4/username"]
            settings.incomingServer = serviceSettings["imap4/server"]
            settings.incomingSecureConnectionIndex = parseInt(serviceSettings["imap4/encryption"])
            settings.incomingPort = serviceSettings["imap4/port"]
            settings.acceptUntrustedCertificates = serviceSettings["imap4/acceptUntrustedCertificates"]
                    ? serviceSettings["imap4/acceptUntrustedCertificates"] : 0
            pushCapable = parseInt(serviceSettings["imap4/pushCapable"])
        } else {
            settings.incomingUsername = serviceSettings["pop3/username"]
            settings.incomingServer = serviceSettings["pop3/server"]
            settings.incomingSecureConnectionIndex = parseInt(serviceSettings["pop3/encryption"])
            settings.incomingPort = serviceSettings["pop3/port"]
            settings.acceptUntrustedCertificates = serviceSettings["pop3/acceptUntrustedCertificates"]
                    ? serviceSettings["pop3/acceptUntrustedCertificates"] : 0
        }

        // check if we have a valid smtp server saved
        // TODO: use CanTransmit flag instead, note old accounts don't have it
        var smtpService = serviceSettings["smtp/servicetype"]
        if (smtpService == "sink") {
            settings.outgoingUsername = serviceSettings["smtp/smtpusername"]
            settings.outgoingServer = serviceSettings["smtp/server"]
            settings.outgoingSecureConnectionIndex = parseInt(serviceSettings["smtp/encryption"])
            settings.outgoingPort = serviceSettings["smtp/port"]
            settings.outgoingRequiresAuth = serviceSettings["smtp/authentication"] || serviceSettings["smtp/authFromCapabilities"]

            // Identity Secret can't be read from db
            settings.outgoingPassword = "default"
            // Avoid to update crendetials if user modifies username but ends up with same as saved
            outgoingUsername = settings.outgoingUsername
        } else {
            skipSmtp = true
            settings.hideOutgoing = true
        }

        // Identity Secret can't be read from db
        settings.incomingPassword = "default"
        // Avoid to update crendetials if user modifies username but ends up with same as saved
        incomingUsername = settings.incomingUsername
    }

    function saveServiceSettings() {
        account.setConfigurationValue(_defaultServiceName, "emailaddress", settings.emailAddress)
        account.setConfigurationValue("", "default_credentials_username", settings.incomingUsername)

        if (settings.serverTypeIndex == 0) {
            //TODO: remove incomingServerType it can't be edit, just for compatibility for old accounts
            account.setConfigurationValue(_defaultServiceName, "incomingServerType", 0)
            account.setConfigurationValue(_defaultServiceName, "imap4/downloadAttachments", 0)
            account.setConfigurationValue(_defaultServiceName, "imap4/username", settings.incomingUsername)
            account.setConfigurationValue(_defaultServiceName, "imap4/server", settings.incomingServer)
            account.setConfigurationValue(_defaultServiceName, "imap4/port", settings.incomingPort)
            account.setConfigurationValue(_defaultServiceName, "imap4/encryption", settings.incomingSecureConnectionIndex)
            account.setConfigurationValue(_defaultServiceName, "imap4/acceptUntrustedCertificates", settings.acceptUntrustedCertificates ? 1 : 0)
        } else {
            account.setConfigurationValue(_defaultServiceName, "incomingServerType", 1)
            account.setConfigurationValue(_defaultServiceName, "customFields/showMoreMails", "false")
            account.setConfigurationValue(_defaultServiceName, "pop3/username", settings.incomingUsername)
            account.setConfigurationValue(_defaultServiceName, "pop3/server", settings.incomingServer)
            account.setConfigurationValue(_defaultServiceName, "pop3/port", settings.incomingPort)
            account.setConfigurationValue(_defaultServiceName, "pop3/encryption", settings.incomingSecureConnectionIndex)
            account.setConfigurationValue(_defaultServiceName, "pop3/acceptUntrustedCertificates", settings.acceptUntrustedCertificates ? 1 : 0)
        }
        if (!skipSmtp) {
            account.setConfigurationValue(_defaultServiceName, "smtp/smtpusername", settings.outgoingUsername)
            account.setConfigurationValue(_defaultServiceName, "smtp/address", settings.emailAddress)
            account.setConfigurationValue(_defaultServiceName, "smtp/server", settings.outgoingServer)
            account.setConfigurationValue(_defaultServiceName, "smtp/port", settings.outgoingPort)
            account.setConfigurationValue(_defaultServiceName, "smtp/encryption", settings.outgoingSecureConnectionIndex)
            // If auth is required set authFromCapabilities to true, if not set to false and also set authentication to 0
            if (!settings.outgoingRequiresAuth) {
                account.setConfigurationValue(_defaultServiceName, "smtp/authentication", 0)
            }
            account.setConfigurationValue(_defaultServiceName, "smtp/authFromCapabilities", settings.outgoingRequiresAuth ? 1 : 0)
            account.setConfigurationValue(_defaultServiceName, "smtp/acceptUntrustedCertificates", settings.acceptUntrustedCertificates ? 1 : 0)
        }
    }

    function _updateIncomingCredentials() {
        var credentialsName
        var incomingPassword
        if (settings.incomingPasswordEdited) {
            incomingPassword = settings.incomingPassword
            settings.incomingPasswordEdited = false
        } else {
            incomingPassword = ""
        }
        credentialsName = (settings.serverTypeIndex == 0) ? "imap4/CredentialsId": "pop3/CredentialsId"
        if (account.hasSignInCredentials("Jolla", credentialsName)) {
            account.updateSignInCredentials("Jolla", credentialsName,
                                            account.signInParameters(_defaultServiceName, settings.incomingUsername, incomingPassword))
        } else {
            // build account configuration map, to avoid another asynchronous state round trip.
            var configValues = { "": account.configurationValues("") }
            var serviceNames = account.supportedServiceNames
            for (var si in serviceNames) {
                configValues[serviceNames[si]] = account.configurationValues(serviceNames[si])
            }
            accountFactory.recreateAccountCredentials(account.identifier, _defaultServiceName,
                                                      settings.incomingUsername, incomingPassword,
                                                      account.signInParameters(_defaultServiceName, settings.incomingUsername, incomingPassword),
                                                      "Jolla", "", credentialsName, configValues)
        }
    }

    function _updateOutgoingCredentials() {
        var outgoingPassword
        if (settings.outgoingPasswordEdited) {
            outgoingPassword = settings.outgoingPassword
            settings.outgoingPasswordEdited = false
        } else {
            outgoingPassword = ""
        }
        var credentialsName = "smtp/CredentialsId"
        if (account.hasSignInCredentials("Jolla", credentialsName)) {
            account.updateSignInCredentials("Jolla", credentialsName,
                                            account.signInParameters(_defaultServiceName, settings.outgoingUsername, outgoingPassword))
        } else {
            // build account configuration map, to avoid another asynchronous state round trip.
            var configValues = { "": account.configurationValues("") }
            var serviceNames = account.supportedServiceNames
            for (var si in serviceNames) {
                configValues[serviceNames[si]] = account.configurationValues(serviceNames[si])
            }
            accountFactory.recreateAccountCredentials(account.identifier, _defaultServiceName,
                                                      settings.outgoingUsername, outgoingPassword,
                                                      account.signInParameters(_defaultServiceName, settings.outgoingUsername, outgoingPassword),
                                                      "Jolla", "", credentialsName, configValues)
        }
    }

    width: parent.width
    spacing: Theme.paddingLarge

    AccountMainSettingsDisplay {
        id: mainAccountSettings
        accountProvider: root.accountProvider
        accountUserName: account.defaultCredentialsUserName
        accountDisplayName: account.displayName
        accountEnabledReadOnly: root.accountIsReadOnly
        accountIsProvisioned: root.accountIsProvisioned
    }

    AccountServiceSettingsDisplay {
        id: serviceSettingsDisplay
        showSectionHeader: false
        autoEnableServices: root.autoEnableAccount
        visible: mainAccountSettings.accountEnabled
    }

    Column {
        id: emailOptions
        width: parent.width
        visible: mainAccountSettings.accountEnabled

        SectionHeader {
            //: Email details
            //% "Details"
            text: qsTrId("settings-accounts-la-details_email")
        }

        TextField {
            id: yourNameField
            width: parent.width
            inputMethodHints: Qt.ImhNoPredictiveText
            //: Placeholder text for your name
            //% "Your name"
            placeholderText: qsTrId("components_accounts-ph-genericemail_your_name")
            //: Your name
            //% "Your name"
            label: qsTrId("components_accounts-la-genericemail_your_name")
        }

        TextSwitch {
            id: signatureEnabledSwitch
            checked: true
            //: Include signature in emails
            //% "Include signature"
            text: qsTrId("settings-accounts-la-include_email_signature")
        }

        TextArea {
            id: signatureField
            width: parent.width
            textLeftMargin: Theme.itemSizeExtraSmall
            //: Placeholder text for signature text area
            //% "Write signature here"
            placeholderText: qsTrId("settings-accounts-ph-email_signature")
            text: {
                if (settingsConf.default_signature_translation_id && settingsConf.default_signature_translation_catalog) {
                    var translated = Format.trId(settingsConf.default_signature_translation_id, settingsConf.default_signature_translation_catalog)
                    if (translated && translated != settingsConf.default_signature_translation_id)
                        return translated
                }

                //: Default signature. %1 is an operating system name without the OS suffix
                //% "Sent from my %1 device"
                return qsTrId("settings_email-la-email_default_signature")
                    .arg(aboutSettings.baseOperatingSystemName)
            }
        }

        SyncScheduleOptions {
            //: Click to show options on how often emails should be fetched from the server
            //% "Sync emails"
            label: qsTrId("settings-accounts-la-sync_emails")
            schedule: root._emailSyncOptions ? root._emailSyncOptions.schedule : null
            isAlwaysOn: root._emailSyncOptions ? root._emailSyncOptions.syncExternallyEnabled : false
            showAlwaysOn: root.pushCapable
            intervalModel: EmailIntervalListModel {}

            onAlwaysOnChanged: {
                root._emailSyncOptions.syncExternallyEnabled = state
            }
        }

        Loader {
            width: parent.width
            height: item ? item.height : 0
            sourceComponent: (root._emailSyncOptions
                              && root._emailSyncOptions.schedule.enabled
                              && root._emailSyncOptions.schedule.peakScheduleEnabled) ? emailPeakOptions : null
            Component {
                id: emailPeakOptions
                PeakSyncOptions {
                    schedule: root._emailSyncOptions.schedule
                    showAlwaysOn: root.pushCapable
                    intervalModel: EmailIntervalListModel {}
                    offPeakIntervalModel: EmailOffPeakIntervalListModel {}
                }
            }
        }

        Loader {
            id: cryptoSection
            property string defaultKey
            property string emailAddress
            property string identity: yourNameField.text
            readonly property string pluginName: item ? item.pluginName : ""
            readonly property string keyIdentifier: item ? item.keyIdentifier : ""
            width: parent.width
            height: item ? item.height : 0

            onDefaultKeyChanged: if (item) {item.defaultKey = defaultKey}
            onEmailAddressChanged: if (item) {item.emailAddress = emailAddress}
            onIdentityChanged: if (item) {item.identity = identity}

            // This is put behind a loader in case the EmailCryptoSection.qml
            // is not installed.
            source: "EmailCryptoSection.qml"
        }
    }

    StandardAccountSettingsLoader {
        id: settingsLoader

        account: root.account
        accountProvider: root.accountProvider
        accountManager: root.accountManager
        accountSyncManager: root._syncManager
        autoEnableServices: root.autoEnableAccount

        onSettingsLoaded: {
            root._emailSyncProfileIds = serviceSyncProfiles["email"]
            var emailOptions = allSyncOptionsForService("email")
            for (var profileId in emailOptions) {
                root._emailSyncOptions = emailOptions[profileId]
                break
            }
        }
    }

    AccountSyncAdapter {
        id: syncAdapter
        accountManager: root.accountManager
    }

    Account {
        id: account

        identifier: root.accountId
        property bool needToUpdateIncoming
        property bool needToUpdateOutgoing

        onStatusChanged: {
            if (status === Account.Initialized) {
                mainAccountSettings.accountEnabled = root.isNewAccount || account.enabled
                _populateEmailDetails()
                if (!root.isNewAccount) {
                    populateServiceSettings()
                }
            } else if (status === Account.Synced) {
                if (!root.isNewAccount && settings) {
                    if (incomingUsername != settings.incomingUsername || settings.incomingPasswordEdited) {
                        needToUpdateIncoming = true
                    }
                    if (!skipSmtp) {
                        if (outgoingUsername != settings.outgoingUsername || settings.outgoingPasswordEdited) {
                            needToUpdateOutgoing = true
                        }
                    }
                    if (needToUpdateIncoming || needToUpdateOutgoing) {
                        updateCredentials()
                    } else if (root._syncProfileWhenAccountSaved) {
                        root._syncProfileWhenAccountSaved = false
                        syncAdapter.triggerSync(account)
                    }
                } else if (root._syncProfileWhenAccountSaved) {
                    root._syncProfileWhenAccountSaved = false
                    syncAdapter.triggerSync(account)
                }
            } else if (status === Account.Error) {
                // display "error" dialog
            } else if (status === Account.Invalid) {
                // successfully deleted
            }
            if (root._saving && status != Account.SyncInProgress) {
                root._saving = false
                root.accountSaveCompleted(status == Account.Synced)
            }
        }

        function updateCredentials() {
            if (needToUpdateIncoming) {
                needToUpdateIncoming = false
                incomingUsername = settings.incomingUsername
                _updateIncomingCredentials()
            } else if (needToUpdateOutgoing) {
                needToUpdateOutgoing = false
                outgoingUsername = settings.outgoingUsername
                _updateOutgoingCredentials()
            }
        }

        onSignInCredentialsUpdated: {
            // Check if we need to perform a sync after update all credentials
            if (!root.isNewAccount && !needToUpdateIncoming && !needToUpdateOutgoing
                    && root._syncProfileWhenAccountSaved) {
                root._syncProfileWhenAccountSaved = false
                syncAdapter.triggerSync(account)
            }
        }

        onSignInError: {
            console.log("Generic email provider account error:", message)
           //What should be done here ?????
        }
    }

    ConfigurationGroup {
        id: settingsConf

        path: "/apps/jolla-settings"

        property string default_signature_translation_id
        property string default_signature_translation_catalog
    }

    AboutSettings {
        id: aboutSettings
    }
}
