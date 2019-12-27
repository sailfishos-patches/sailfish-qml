import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

AccountCredentialsAgent {
    id: root

    property AccountSyncManager _syncManager: AccountSyncManager {}

    canCancelUpdate: true

    initialPage: Dialog {
        id: updateDialog

        acceptDestinationAction: PageStackAction.Push // has to be, so this page continues to live, so it can call _updateCredentials() AFTER accepted()
        acceptDestination: AccountBusyPage { // intermediate page - to handle success/errors
            busyDescription: updatingAccountText
        }

        property bool _updateAccepted
        property string _signonServiceName
        property string _oldUsername: account.defaultCredentialsUserName // we load the "real" username later.

        function _updateCredentials() {
            if (account.hasSignInCredentials("Jolla", "Jolla")) {
                account.updateSignInCredentials("Jolla", "Jolla",
                                                account.signInParameters(_signonServiceName, _oldUsername, passwordField.text))
            } else {
                // build account configuration map, to avoid another asynchronous state round trip.
                var configValues = { "": account.configurationValues("") }
                var serviceNames = account.supportedServiceNames
                for (var si in serviceNames) {
                    configValues[serviceNames[si]] = account.configurationValues(serviceNames[si])
                }
                accountFactory.recreateAccountCredentials(account.identifier, _signonServiceName,
                                                          _oldUsername, passwordField.text,
                                                          account.signInParameters(_signonServiceName, _oldUsername, passwordField.text),
                                                          "Jolla", "", "Jolla", configValues)
            }
        }

        canAccept: passwordField.text.length > 0

        onOpened: {
            var services = account.supportedServiceNames
            for (var i=0; i<services.length; i++) {
                var service = accountManager.service(services[i])
                var profileIds = root._syncManager.profileIds(account.identifier, service.name)
                if (profileIds.length > 0 && profileIds[0] !== "") {
                    _signonServiceName = service.name
                    break
                }
            }
        }

        onStatusChanged: {
            // we don't do this in onAccepted(), otherwise the _updateCredentials()
            // operation might complete before the page transition is completed,
            // in which case the attempt to then transition to the final destination
            // would fail.  So, we wait until the initial transition is complete, first.
            if (status == PageStatus.Inactive && result == DialogResult.Accepted) {
                _updateCredentials()
            }
        }

        onRejected: {
            if (account.status === Account.SigningIn) {
                account.cancelSignInOperation()
            }
        }

        DialogHeader {
            id: pageHeader
        }

        Column {
            id: col
            anchors.top: pageHeader.bottom
            spacing: Theme.paddingLarge
            width: parent.width

            Label {
                //: Prompt telling the user which username the new password is for
                //% "Enter new password for user '%1':"
                text: qsTrId("components_accounts-la-enter_new_password").arg(updateDialog._oldUsername)
                wrapMode: Text.WordWrap
                x: Theme.horizontalPageMargin
                width: parent.width - x*2
                color: Theme.rgba(Theme.highlightColor, Theme.opacityHigh)
            }

            PasswordField {
                id: passwordField
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: root.focus = true
            }
        }
    }

    Account {
        id: account
        identifier: root.accountId

        onSignInCredentialsUpdated: {
            root.credentialsUpdated(identifier)
            root.goToEndDestination()
        }

        onSignInError: {
            root.credentialsUpdateError(errorMessage)
            var busyPage = updateDialog.acceptDestination
            busyPage.state = 'info'
            busyPage.infoHeading = busyPage.errorHeadingText
            busyPage.infoDescription = busyPage.accountUpdateErrorText
        }
    }
}
