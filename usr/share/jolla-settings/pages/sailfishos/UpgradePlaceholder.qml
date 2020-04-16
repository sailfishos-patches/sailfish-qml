import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.sailfishos 1.0

ViewPlaceholder {
    text: {
        if (storeIf.accessDenied) {
            //% "No access rights to Sailfish OS upgrades"
            return qsTrId("settings_sailfishos-li-sailfish_os_upgrade_access_denied")
        } else if (storeIf.ssuRequiresRegistration) {
            //% "Developer updates not enabled"
            return qsTrId("settings_sailfishos-li-developer_updates_not_enabled")
        } else if (storeIf.accountStatus === StoreInterface.AccountNotAvailable) {
            //: View placeholder when there's no Jolla account created or the user has not yet signed in
            //% "Jolla account needed"
            return qsTrId("settings_sailfishos-li-account_needed")
        } else {
            //: View placeholder text shown when there's some problem with the account
            //: that requires the user to go to settings and sign in again.
            //% "Jolla account needs to be updated"
            return qsTrId("settings_sailfishos-li-account_needs_update")
        }
    }

    hintText: {
        if (storeIf.accessDenied) {
            return ""
        } else if (storeIf.ssuRndModeRequiresRegistration) {
            //% "Device in R&D mode. Updating requires registration in Settings | System | Developer tools"
            return qsTrId("settings_sailfishos-li-rnd_ssu_registration_required")
        } else if (storeIf.ssuCbetaRequiresRegistration) {
            //% "Device in CBeta domain. Updating requires registration in Settings | System | Developer tools"
            return qsTrId("settings_sailfishos-li-cbeta_domain_ssu_registration_required")
        } else if (storeIf.ssuDomainRequiresRegistration) {
            //% "Device in '%0' domain. Updating requires registration in Settings | System | Developer tools"
            return qsTrId("settings_sailfishos-li-custom_domain_ssu_registration_required").arg(ssu.domain)
        } else {
            //% "Settings | Accounts"
            var link = "<a href='account'>" + qsTrId("settings_sailfishos-la-settings_accounts") + "</a>"

            return storeIf.accountStatus === StoreInterface.AccountNotAvailable
                    ? //: View placeholder hint text shown when there's no Jolla account created or
                      //: the user has not yet signed in.
                      //: Takes "Settings | Accounts" (settings_sailfishos-la-settings_accounts) as parameter.
                      //: This is done because we're creating programmatically a hyperlink for it.
                      //% "Go to %1 and create an account"
                      qsTrId("settings_sailfishos-li-account_needed_hint_text").arg(link)

                    : //: View placeholder hint text shown when there's some problem with the account
                      //: that requires the user to go to settings and sign in again.
                      //: Takes "Settings | Accounts" (settings_sailfishos-la-settings_accounts) as parameter.
                      //: This is done because we're creating programmatically a hyperlink for it.
                      //% "Go to %1 and sign in again"
                      qsTrId("settings_sailfishos-li-account_needs_update_hint_text").arg(link)
        }
    }

    _hintLabel.textFormat: Text.StyledText
    _hintLabel.linkColor: Theme.primaryColor
    _hintLabel.onLinkActivated: pageStack.animatorPush(Qt.resolvedUrl("../accounts/mainpage.qml"))
}
