import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0
import com.jolla.sailfisheas 1.0
import "SailfishEasSettings.js" as ServiceSettings

Column {
    id: root

    property bool autoEnableAccount
    property bool isNewAccount
    property string defaultServiceName: accountProvider.serviceNames[0]
    property string username
    property alias accountEnabled: mainAccountSettings.accountEnabled
    property int accountId
    property Provider accountProvider
    property AccountManager accountManager
    property Item connectionSettings
    property Item busyPage
    property alias _account: account
    property bool _provisioningChecked
    property string _emailProfileId
    property string _calendarProfileId
    property string _contactsProfileId
    property int _credentialsUpdateCounter
    property bool _saving
    property bool _triggerSyncWhenAccountSaved

    signal accountSaveCompleted(var success)

    function _populateServiceSettings() {
        // Global account configuration / settings
        var accountGlobalSettings = account.configurationValues("")
        easSettings.conflictsIndex = parseInt(accountGlobalSettings["conflict_policy"]) === 0 ? 1 : 0
        easSettings.provision = !accountGlobalSettings["disable_provision"]
        easSettings.setSyncPolicy(accountGlobalSettings["folderSyncPolicy"])

        // Email
        var accountEmailSettings = account.configurationValues("sailfisheas-email")
        easSettings.mail = accountEmailSettings["enabled"]
        easSettings.pastTimeEmailIndex = parseInt(accountEmailSettings["sync_past_time"]) - 1

        // Email details
        var signature = accountEmailSettings["signature"]
        if (signature) {
            easSettings.signature = signature
        }
        easSettings.signatureEnabled = accountEmailSettings["signatureEnabled"]

        easSettings.isNewAccount = root.isNewAccount

        // Calendar
        var accountCalendarSettings = account.configurationValues("sailfisheas-calendars")
        easSettings.calendar = accountCalendarSettings["enabled"]
        var pastTimeCal = parseInt(accountCalendarSettings["sync_past_time"])
        easSettings.pastTimeCalendarIndex = pastTimeCal > 3 ? pastTimeCal - 4 : 4

        // Contacts
        var accountContatcsSettings = account.configurationValues("sailfisheas-contacts")
        easSettings.contacts = accountContatcsSettings["enabled"]
        easSettings.contacts2WaySync = accountContatcsSettings["sync_local"]

        // Avoid to update credentials if user modifies username but ends up with same as saved
        username = accountGlobalSettings["connection/username"] || ""

        // Server connection settings
        connectionSettings.acceptSSLCertificates = accountGlobalSettings["connection/accept_all_certificates"] || false
        connectionSettings.domain = accountGlobalSettings["connection/domain"] || ""
        connectionSettings.emailaddress = accountGlobalSettings["connection/emailaddress"] || ""
        connectionSettings.port = accountGlobalSettings["connection/port"] || 443

        // To respect key if it exists, use "in" to check existence.
        // Other similar tests shave reasonable fallback values.
        connectionSettings.secureConnection = ("connection/secure_connection" in accountGlobalSettings)
                ? accountGlobalSettings["connection/secure_connection"]
                : true
        connectionSettings.server = accountGlobalSettings["connection/server_address"] || ""
        connectionSettings.username = accountGlobalSettings["connection/username"] || ""

        if (accountGlobalSettings["SslCertCredentialsId"]) {
            connectionSettings.loadCertificateData(accountGlobalSettings["SslCertCredentialsId"],
                                                   accountGlobalSettings["connection/ssl_certificate_path"])
        }

        // can't read 'password' from DB, so initialising it with some placeholder value
        connectionSettings.password = "default"

        _credentialsUpdateCounter = parseInt(accountEmailSettings["credentials_update_counter"])
    }

    function saveAccount(blockingSave, saveConnectionSettings) {
        console.log("[jsa-eas] Saving account")
        account.enabled = mainAccountSettings.accountEnabled
        account.displayName = mainAccountSettings.accountDisplayName

        if (saveConnectionSettings) {
            ServiceSettings.saveConnectionSettings(connectionSettings)
        }

        if (!root.isNewAccount) {
            saveSettings()

            _saving = true
            if (blockingSave) {
                account.blockingSync()
            } else {
                account.sync()
            }
        } else {
            // Don't save the settings yet, otherwise eas-daemon can start syncing the acct
            if (easSettings.provision) {
                busyPage.currentTask = "checkProvisioning"
            } else {
                busyPage.currentTask = "savingAccount"
                saveSettings()
            }
            // The sync will be triggered later by the busy page status change
        }
    }

    function accountSaveSync() {
        _saving = true
        account.sync()
    }

    function saveAccountAndTriggerSync(saveConnectionSettings) {
        root._triggerSyncWhenAccountSaved = true
        saveAccount(false, saveConnectionSettings)
    }

    function saveSettings() {
        console.log("[jsa-eas] Saving account settings")
        _saveScheduleProfile()
        ServiceSettings.saveSettings(easSettings)
        if (root.isNewAccount) {
            // Save service here, since settings loader can overwrite those for new accounts
            if (easSettings.mail) {
                account.enableWithService("sailfisheas-email")
            } else {
                account.disableWithService("sailfisheas-email")
            }

            if (easSettings.calendar) {
                account.enableWithService("sailfisheas-calendars")
            } else {
                account.disableWithService("sailfisheas-calendars")
            }

            if (easSettings.contacts) {
                account.enableWithService("sailfisheas-contacts")
            } else {
                account.disableWithService("sailfisheas-contacts")
            }
        }
    }

    function _saveScheduleProfile() {
        console.log("[jsa-eas] Saving profile schedule")
        var hasSchedule = (easSettings.syncScheduleOptions !== null &&
                           easSettings.syncScheduleOptions.schedule !== null)
        var sharedScheduleEnabled = hasSchedule ? easSettings.syncScheduleOptions.schedule.enabled : false
        // Email profile
        if (root._emailProfileId != "") {
            if (sharedScheduleEnabled && !easSettings.mail) {
                // disable the schedule since the service is disabled
                easSettings.syncScheduleOptions.schedule.enabled = false
            }
            var emailPropertiesObject = { "enabled": easSettings.mail ? "true" : "false" }
            syncManager.updateProfile(root._emailProfileId, emailPropertiesObject,
                                      easSettings.syncScheduleOptions)
        }
        // Calendar profile
        if (root._calendarProfileId != "") {
            if (sharedScheduleEnabled && !easSettings.calendar) {
                // disable the schedule since the service is disabled
                easSettings.syncScheduleOptions.schedule.enabled = false
            }
            var calendarPropertiesObject = { "enabled": easSettings.calendar ? "true" : "false" }
            syncManager.updateProfile(root._calendarProfileId, calendarPropertiesObject,
                                      easSettings.syncScheduleOptions)
        }
        if (root._contactsProfileId != "") {
            if (sharedScheduleEnabled && !easSettings.contacts) {
                // disable the schedule since the service is disabled
                easSettings.syncScheduleOptions.schedule.enabled = false
            }
            var contactsPropertiesObject = { "enabled": easSettings.contacts ? "true" : "false" }
            syncManager.updateProfile(root._contactsProfileId, contactsPropertiesObject,
                                      easSettings.syncScheduleOptions)
        }
        if (hasSchedule) {
            easSettings.syncScheduleOptions.schedule.enabled = sharedScheduleEnabled
        }
    }

    function increaseCredentialsCounter() {
        _credentialsUpdateCounter++
        // Save a string since double is not supported in c++ side:  'Account::setConfigurationValues(): variant type  QVariant::double'
        account.setConfigurationValue("sailfisheas-email", "credentials_update_counter", _credentialsUpdateCounter.toString())
    }

    CheckProvision {
        id: checkProvisionService
        onCheckProvisionDone: {
            console.log("[jsa-eas] CheckProvision - OK")
            if (root.busyPage !== null) {
                if (checkProvisionService.provisionStatus === CheckProvision.PROVISION_POLICY_NOT_REQUIRED ||
                    checkProvisionService.provisionStatus === CheckProvision.PROVISION_POLICY_REQUIRED_SUCCESS) {
                    root.saveSettings()
                    account.sync()
                } else if (checkProvisionService.provisionStatus === CheckProvision.PROVISION_POLICY_REQUIRED_NOT_IMPLEMENTED) {
                    root.busyPage.operationFailed("ProvCheck NotImplemented")
                } else if (checkProvisionService.provisionStatus === CheckProvision.PROVISION_POLICY_REQUIRED_FAILED) {
                    if (!checkProvisionService.devicePassword) {
                        root.busyPage.operationFailed("ProvCheck DevLockNeeded")
                    } else if (checkProvisionService.maxInactivityTimeDeviceLock > 0) {
                        root.busyPage.maxInactivityTimeDeviceLock = checkProvisionService.maxInactivityTimeDeviceLock
                        root.busyPage.operationFailed("ProvCheck MaxTimeDeviceLock")
                    } else {
                        root.busyPage.operationFailed("ProvCheck NotImplemented")
                    }
                } else {
                    // NOTE: according to current implementation fail to fit other required policies will lead to 'NotImplemented' status
                    root.busyPage.operationFailed("ProvCheck NotImplemented")
                }
            }
            root._provisioningChecked = true
        }
        onCheckProvisionFailed: {
            console.log("[jsa-eas] CheckProvisionFailed!\n error == " + error + " | provisionStatus == " + checkProvisionService.provisionStatus)
            if (root.busyPage !== null) {
                if (error === CheckProvision.CHECKPROVISION_ERROR_PROTOCOL) {
                    console.log("[jsa-eas] CheckProvision - Server doesn't support provisioning request for the used protocol")
                }
                root.busyPage.operationFailed("ProvCheck failed")
            }
            root._provisioningChecked = false
        }
    }

    width: parent.width
    spacing: Theme.paddingLarge

    AccountMainSettingsDisplay {
        id: mainAccountSettings
        accountProvider: root.accountProvider
        accountUserName: root.username
        accountDisplayName: account.displayName
        accountIsProvisioned: account.provisioned
        accountEnabledReadOnly: account.readonly
    }

    AccountServiceSettingsDisplay {
        showSectionHeader: false
        visible: mainAccountSettings.accountEnabled
    }

    SailfishEasCommon {
        id: easSettings
        opacity: mainAccountSettings.accountEnabled ? 1 : 0
        visible: opacity > 0.0

        Behavior on opacity { FadeAnimation {} }
    }

    StandardAccountSettingsLoader {
        account: root._account
        accountProvider: root.accountProvider
        accountManager: root.accountManager
        accountSyncManager: syncManager
        autoEnableServices: root.autoEnableAccount
        onSettingsLoaded: {
            // Load the initial settings. Each of these services only have one sync profile.
            var profileId = 0
            // Email profile contains the main sync settings
            var syncOptions = allSyncOptionsForService("sailfisheas-email")
            for (profileId in syncOptions) {
                easSettings.syncScheduleOptions = syncOptions[profileId]
                break
            }
            // Getting email sync profile
            var emailProfileIds = accountSyncManager.profileIds(account.identifier,
                                                                "sailfisheas-email")
            if (emailProfileIds.length > 0 && emailProfileIds[0] !== "") {
                root._emailProfileId = emailProfileIds[0]
            }
            // Getting calendars sync profile
            var calendarsProfileIds = accountSyncManager.profileIds(account.identifier,
                                                                    "sailfisheas-calendars")
            if (calendarsProfileIds.length > 0 && calendarsProfileIds[0] !== "") {
                root._calendarProfileId = calendarsProfileIds[0]
            }
            // Getting contacts sync profile
            var _contactsProfileIds = accountSyncManager.profileIds(account.identifier,
                                                                   "sailfisheas-contacts")
            if (_contactsProfileIds.length > 0 && _contactsProfileIds[0] !== "") {
                root._contactsProfileId = _contactsProfileIds[0]
            }
        }
    }

    AccountSyncAdapter {
        id: syncAdapter
        accountManager: root.accountManager
    }

    AccountSyncManager {
        id: syncManager
    }

    Account {
        id: account
        identifier: root.accountId

        onStatusChanged: {
            if (status === Account.Initialized) {
                mainAccountSettings.accountEnabled = root.isNewAccount || account.enabled
                root._populateServiceSettings()
            } else if (status === Account.Synced) {
                // success
                if (!root.isNewAccount) {
                    if (username !== connectionSettings.username || connectionSettings.passwordEdited) {
                        username = connectionSettings.username
                        var password = ""
                        if (connectionSettings.passwordEdited) {
                            password = connectionSettings.password
                            connectionSettings.passwordEdited = false
                        }
                        account.updateSignInCredentials( "Jolla", "ActiveSync",
                                        account.signInParameters(defaultServiceName, connectionSettings.username, password))
                    } else if (root._triggerSyncWhenAccountSaved) {
                        root._triggerSyncWhenAccountSaved = false
                        syncAdapter.triggerSync(account)
                    }
                } else {
                    if (easSettings.provision && !_provisioningChecked) {
                        console.log("[jsa-eas] starting checkProv from acc.synced ", account.identifier)
                        // TODO
                        checkProvisionService.checkSettings(identifier)
                    } else {
                        if (root._provisioningChecked) {
                            root.busyPage.operationSucceeded()
                        }
                        console.log("[jsa-eas] Trigger sync for account ", account.identifier)
                        syncAdapter.triggerSync(account)
                    }
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

        onSignInCredentialsUpdated: {
            console.log("[jsa-eas] Credentials updated sucessfully")
            if (root._triggerSyncWhenAccountSaved) {
                root._triggerSyncWhenAccountSaved = false
                syncAdapter.triggerSync(account)
            }
            root.increaseCredentialsCounter()
            sync()
        }

        onSignInError: {
            console.log("[jsa-eas] Failed to update credentials")
            console.log("ActiveSync provider account error:", message)
            // TODO: what should be done here?
        }
    }
}
