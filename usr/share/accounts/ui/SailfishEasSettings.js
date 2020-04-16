function saveSettings(settings) {
    // General
    account.setConfigurationValue("", "conflict_policy", settings.conflictsIndex === 0 ? 1 : 0)
    account.setConfigurationValue("", "disable_provision", !settings.provision)
    account.setConfigurationValue("", "folderSyncPolicy", settings.syncPolicy)

    // Mail
    account.setConfigurationValue("sailfisheas-email", "signature", settings.signature)
    account.setConfigurationValue("sailfisheas-email", "signatureEnabled", settings.signatureEnabled)
    account.setConfigurationValue("sailfisheas-email", "enabled", settings.mail)
    account.setConfigurationValue("sailfisheas-email", "sync_past_time", pastTimeValueFromIndex(settings.pastTimeEmailIndex, 2, true))

    // Calendar
    account.setConfigurationValue("sailfisheas-calendars", "name", account.displayName)
    account.setConfigurationValue("sailfisheas-calendars", "enabled", settings.calendar)
    account.setConfigurationValue("sailfisheas-calendars", "sync_past_time", pastTimeValueFromIndex(settings.pastTimeCalendarIndex, 4, false))

    // Contacts
    account.setConfigurationValue("sailfisheas-contacts", "enabled", settings.contacts)
    account.setConfigurationValue("sailfisheas-contacts", "sync_local", settings.contacts2WaySync)
}

function saveConnectionSettings(connectionSettings) {
    if (connectionSettings !== null) {
        account.setConfigurationValue("", "connection/accept_all_certificates", connectionSettings.acceptSSLCertificates)
        account.setConfigurationValue("", "connection/domain", connectionSettings.domain)
        account.setConfigurationValue("", "connection/emailaddress", connectionSettings.emailaddress)
        account.setConfigurationValue("", "connection/port", connectionSettings.port)
        account.setConfigurationValue("", "connection/secure_connection", connectionSettings.secureConnection)
        account.setConfigurationValue("", "connection/server_address", connectionSettings.server)
        account.setConfigurationValue("", "connection/username", connectionSettings.username)

        //Email address is also need in the email service, to be used as from address
        account.setConfigurationValue("sailfisheas-email", "emailaddress", connectionSettings.emailaddress)

        account.setConfigurationValue("", "SslCertCredentialsId", connectionSettings.sslCredentialsId)
        account.setConfigurationValue("", "connection/ssl_certificate_path",
                                      (connectionSettings.hasSslCertificate && connectionSettings.sslCredentialsId > 0)
                                      ? connectionSettings.sslCertificatePath : "")

    } else {
        console.log("[eas] Warning! Unable to save settings from invalid dialog.")
    }
}

function pastTimeValueFromIndex(index, defaultValue, isEmail) {
    if (isEmail) {
        switch (index) {
        case 0: return 1    //CFG_PASTTIME_1_DAY
        case 1: return 2    //CFG_PASTTIME_3_DAYS    - default
        case 2: return 3    //CFG_PASTTIME_1_WEEK
        case 3: return 4    //CFG_PASTTIME_2_WEEKS
        case 4: return 5    //CFG_PASTTIME_1_MONTH
        default: return defaultValue
        }
    } else {
        switch (index) {
        case 0: return 4    //CFG_PASTTIME_2_WEEKS  - default
        case 1: return 5    //CFG_PASTTIME_1_MONTH
        case 2: return 6    //CFG_PASTTIME_3_MONTHS
        case 3: return 7    //CFG_PASTTIME_6_MONTHS
        case 4: return 0    //CFG_PASTTIME_ALL
        default: return defaultValue
        }
    }
}
