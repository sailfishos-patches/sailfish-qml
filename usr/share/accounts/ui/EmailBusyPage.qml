import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0
import org.nemomobile.email 0.1

AccountBusyPage {
    id: busyPage

    property bool hideIncomingSettings
    property bool skipping
    property bool errorOccured
    property string currentTask
    property bool settingsRetrieved
    property Item settingsDialog

    //: Save account without smtp server
    //% "Save"
    property string saveButtonText: qsTrId("components_accounts-bt-save_without_smtp")

    busyDescription: currentTask === "settingsDiscovery"
                           //: Notifies user that we are trying to retrieve the account settings
                           //% "Discovering account settings..."
                         ? qsTrId("components_accounts-la-genericemail_discovering")
                           //: Checking account credentials
                           //% "Checking account credentials..."
                         : qsTrId("components_accounts-la-genericemail_checking_credentials")

    function _prepareForSkip() {
        infoButtonText = skipButtonText
    }

    function _prepareForSkipSmtpCreation() {
       hideIncomingSettings = true
       infoButtonText = saveButtonText
    }

    function operationSucceeded() {
        errorOccured = false
        if (currentTask === "checkCredentials") {
            pageStack.animatorReplace(settingsDialog)
        } else if (currentTask === "settingsDiscovery") {
            if (!settingsRetrieved) {
                pageStack.pop()
            }
        }
    }

    function operationFailed(serverType, error) {
        errorOccured = true
        infoButtonText = ""
        state = "info"

        if (error === EmailAccount.ConnectionError || error === EmailAccount.ExternalComunicationError) {
            //: Error displayed when connection to the server can't be performed due to connection error.
            //% "Connection error"
            infoHeading = qsTrId("components_accounts-he-genericemail_connection_error")
            _prepareForSkip()
            if (serverType === EmailAccount.IncomingServer) {
                //: Description displayed when connection to the incoming server can't be performed due connection error.
                //% "Connection to your incoming email server failed, please check your internet connection and your server connection settings. Go back to try again or skip now and add this account later."
                infoExtraDescription = qsTrId("components_accounts-la-genericemail_incoming_connection_error_description")
                _prepareForSkip()
            } else {
                //: Description displayed when connection to the outgoing can't be performed due connection error..
                //% "Connection to your outgoing email server failed, please check your internet connection and your server connection settings. Go back to try again or save this account without a outgoing email server configuration, this account won't be available for email sending."
                infoExtraDescription = qsTrId("components_accounts-la-genericemail_outgoing_connection_error_description")
                _prepareForSkipSmtpCreation()
            }
        } else if (error === EmailAccount.DiskFull) {
            //: Error displayed when account can't be saved due to device disk full.
            //% "No space available"
            infoHeading = qsTrId("components_accounts-he-genericemail_diskfull_error")
            //: Description displayed when device disk if full and account can't be saved.
            //% "Your device memory is full, please free some space in order to save this account. Go back to try again or skip now and add this account later."
            infoExtraDescription = qsTrId("components_accounts-la-genericemail_diskfull_description")
            _prepareForSkip()
        } else if (error === EmailAccount.InvalidConfiguration || error === EmailAccount.InternalError) {
            //: Error displayed when the configuration is invalid.
            //% "Invalid configuration"
            infoHeading = qsTrId("components_accounts-he-genericemail_invalid_configuration")
            if (serverType === EmailAccount.IncomingServer) {
                //: Description displayed when incoming server configuration is invalid.
                //% "Go back to correct your incoming email server settings or skip now and add this account later."
                infoExtraDescription = qsTrId("components_accounts-la-genericemail_invalid_configuration_description")
                _prepareForSkip()
            } else {
                //: Description displayed when outgoing server configuration is invalid.
                //% "Go back to correct your outgoing email server connection settings or save this account without a outgoing email server configuration, this account won't be available for email sending."
                infoExtraDescription = qsTrId("components_accounts-la-genericemail_outgoing_authentication_failed_description")
                _prepareForSkipSmtpCreation()
            }
        } else if (error === EmailAccount.LoginFailed) {
            //: Authentication failed error.
            //% "Authentication failed"
            infoHeading = qsTrId("components_accounts-he-genericemail_authentication_failed")
            if (serverType === EmailAccount.IncomingServer) {
                //: Description displayed when authentication fails for incoming server.
                //% "Go back to correct your incoming email server connection settings or skip now and add this account later."
                infoExtraDescription = qsTrId("components_accounts-la-genericemail_incoming_authentication_failed_description")
                _prepareForSkip()
            } else {
                //: Description displayed when authentication fails for outgoing server.
                //% "Go back to correct your outgoing email server connection settings or save this account without a outgoing email server configuration, this account won't be available for email sending."
                infoExtraDescription = qsTrId("components_accounts-la-genericemail_outgoing_authentication_failed_description")
                _prepareForSkipSmtpCreation()
            }
        } else if (error === EmailAccount.Timeout) {
            //: Error displayed when connection to the server timeout.
            //% "Connection timeout"
            infoHeading = qsTrId("components_accounts-he-genericemail_timeout")
            if (serverType === EmailAccount.IncomingServer) {
                //: Description displayed when connection to the incoming server timeout.
                //% "Connection to your incoming email server timeout, please check your internet connection and your server connection settings. Go back to try again or skip now and add this account later."
                infoExtraDescription = qsTrId("components_accounts-la-genericemail_timeout_incoming_description")
                _prepareForSkip()
            } else {
                //: Description displayed when connection to the outgoing server timeout.
                //% "Connection to your outgoing email server timeout, please check your internet connection your server connection settings. Go back to try again or save this account without a outgoing mail server configuration, this account won't be available for email sending."
                infoExtraDescription = qsTrId("components_accounts-la-genericemail_timeout_outgoing_description")
                _prepareForSkipSmtpCreation()
            }
        } else if (error === EmailAccount.UntrustedCertificates) {
            //: Error displayed when the server certificates are untrusted.
            //% "Untrusted certificates"
            infoHeading = qsTrId("components_accounts-he-genericemail_untrustedCertificates")
            if (serverType === EmailAccount.IncomingServer) {
                //: Description displayed when incoming email server certificates are untrusted or invalid.
                //% "Unable to connect to your incoming email server due to untrusted certificates. If your certificates are self-signed you can go back and accept all untrusted certificates or skip now and add this account later."
                infoExtraDescription = qsTrId("components_accounts-la-genericemail_untrustedCertificates_incoming_description")
                _prepareForSkip()
            } else {
                //: Description displayed when outgoing email server certificates are untrusted.
                //% "Unable to connect to your outgoing email server due to untrusted certificates. If your certificates are self-signed you can go back and accept all untrusted certificate or continue and save this account without a outgoing mail server configuration, this account won't be available for email sending."
                infoExtraDescription = qsTrId("components_accounts-la-genericemail_untrustedCertificates_outgoing_description")
                _prepareForSkipSmtpCreation()
            }
        } else {
            // InvalidAccount case
            //: Error displayed when account failed to be added
            //% "Oops, account could not be added"
            infoHeading = qsTrId("components_accounts-he-genericemail_error")
            // Account is removed at this point, don't allow back navigation
            backNavigation = false
            _prepareForSkip()
        }
    }
}
