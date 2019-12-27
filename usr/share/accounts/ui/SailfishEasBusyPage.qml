import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import Sailfish.Silica.theme 1.0
import com.jolla.settings.accounts 1.0

AccountBusyPage {
    id: root

    property bool _errorOccured
    property string currentTask
    property int maxInactivityTimeDeviceLock

    function _prepareForSkip() {
        infoButtonText = skipButtonText
    }

    function operationFailed(errorMessage) {
        _errorOccured = true
        infoButtonText = ""
        state = "info"
        infoDescription = root.accountCreationErrorText

        if (errorMessage === "SSL failed") {
            //: Error displayed when the server certificates are untrusted.
            //% "Untrusted certificates"
            infoHeading = qsTrId("components_accounts-he-activesync-ssl-check-failed")
            //: Description displayed when server certificates are untrusted or invalid.
            //% "Unable to connect to your server due to untrusted certificates. "
            //% "If your certificates are self-signed you can go back and accept all untrusted certificates or skip now and add this account later."
            infoExtraDescription = qsTrId("components_accounts-la-activesync-untrustedCertificates")
            _prepareForSkip()
        } else if (currentTask === "checkCredentials") {
            //: Heading displayed when an connection parameters couldn't be obtained from server.
            //% "Credentials check failed"
            infoHeading = qsTrId("components_accounts-he-activesync-credentials-check-failed")
            //% "Go back to correct your credentials or skip now and add this account later."
            infoExtraDescription = qsTrId("components_accounts-la-activesync-credentials-failed")
            _prepareForSkip()
        } else if (currentTask === "checkProvisioning") {
            //: Heading displayed when server policies couldn't be obtained from server or couldn't be satisfied.
            //% "The account could not be Added."
            infoHeading = qsTrId("components_accounts-he-activesync-provisioning-failed")
            infoDescription = ""
            if (errorMessage === "ProvCheck DevLockNeeded") {
                //: Description displayed when some of required policies couldn't be satisfied
                //% "Account's server settings and policies require the device lock to be set. "
                //% "You can enable the device lock under Settings | Security | Device lock, and then create this account again."
                infoExtraDescription = qsTrId("components_accounts-la-activesync-provisioning-devlock-required")
            } else if (errorMessage === "ProvCheck MaxTimeDeviceLock") {
                //: Description displayed when some of required policies couldn't be satisfied
                //% "Account's server settings and policies require automatic locking to be at least %n minutes. "
                //% "You can change the automatic lock time under Settings | Security | Device lock, and then create this account again."
                infoExtraDescription = qsTrId("components_accounts-la-activesync-provisioning-maxinactivetime-required", maxInactivityTimeDeviceLock)
            } else if (errorMessage === "ProvCheck NotImplemented") {
                //: Description displayed when some of required policies couldn't be satisfied
                //% "Some of server settings and policies required by this account are not supported by the device."
                infoExtraDescription = qsTrId("components_accounts-la-activesync-provisioning-not-supported")
            } else if (errorMessage === "ProvCheck failed") {
                //: Description displayed when the provisioning check fails for some unknown reason (such as the Internet being down)
                //% "There was an error contacting the server about the policies it requires."
                infoExtraDescription = qsTrId("components_accounts-la-activesync-provisioning-failed")
            }

            _prepareForSkip()
        } else {
            console.log("[jsa-eas] Unknown operation failed!")
            infoHeading = root.errorHeadingText
            _prepareForSkip()
        }
    }

    onCurrentTaskChanged: {
        state = "busy"

        if (currentTask === "autodiscovery") {
            //: Notifies user that the account connection details are currently being requested.
            //% "Discovering server settings..."
            busyDescription = qsTrId("components_accounts-la-activesync-autodiscovery")
        } else if (currentTask === "checkCredentials") {
            //: Notifies user that the account credentials are currently being verified.
            //% "Checking credentials..."
            busyDescription = qsTrId("components_accounts-la-activesync-checking-credentials")
        } else if (currentTask === "checkProvisioning") {
            //: Notifies user that the provisioning parameters are currently being verified.
            //% "Checking server settings and policies..."
            busyDescription = qsTrId("components_accounts-la-activesync-checking-provisioning")
        } else if (currentTask === "savingAccount") {
            //% "Saving account..."
            busyDescription = qsTrId("components_accounts-la-activesync-saving-account")
        } else if (currentTask === "creatingAccount") {
            busyDescription = root.creatingAccountText
        }
    }
}
