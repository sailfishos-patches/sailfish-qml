import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.accounts 1.0
import org.pycage.jollastore 1.0
import Nemo.DBus 2.0

Page {
    id: signinPage
    objectName: "SignInPage"

    property alias viewPlaceholderEnabled: viewPlaceholder.enabled

    onStatusChanged: {
        if (status === PageStatus.Active) {
            jollaStore.tryConnect()
        }
    }

    Connections {
        target: win
        onApplicationActiveChanged: {
            if (win.applicationActive && jollaStore.isOnline) {
                // An account may have been created by some other app (e.g. settings).
                jollaStore.tryConnect()
            }
        }
    }

    AccountCreationManager {
        id: jollaAccountSetup

        function start() {
            if (jollaStore.accountState === AccountState.NoAccount) {
                if (jollaStore.isOnline) {
                    if (pageStack.currentPage == signinPage) {
                        jollaAccountSetup.startAccountCreationForProvider("jolla", {}, win.applicationActive ? PageStackAction.Animated : PageStackAction.Immediate)
                    }
                } else if (win.applicationActive) {
                    jollaStore.tryGoOnline()
                }
            }
        }

        endDestination: welcomePage
        endDestinationAction: PageStackAction.Replace
        endDestinationReplaceTarget: null

        onAccountCreated: {
            jollaStore.tryConnect()
        }
    }

    SilicaListView {
        anchors.fill: parent
        header: PageHeader {
            //: Page header for the sign in page
            //% "Jolla Store"
            title: qsTrId("jolla-store-he-sign_in")
            opacity: viewPlaceholder.opacity
        }

        PullDownMenu {
            visible: jollaStore.accountState === AccountState.NoAccount

            AddAccountMenuItem {
                onClicked: {
                    jollaAccountSetup.start()
                }
            }
        }

        ViewPlaceholder {
            id: viewPlaceholder
            enabled: jollaStore.connectionState === JollaStore.Unauthorized ||
                     !jollaStore.isOnline
            text: {
                if (jollaStore.connectionState === JollaStore.Unauthorized) {
                    switch (jollaStore.accountState) {
                    case AccountState.NeedsUpdate:
                        return jollaStore.accountNeedsUpdateMessage()
                    case AccountState.NoAccount:
                        return jollaStore.accountNeededMessage();
                    case AccountState.NetworkError:
                        return jollaStore.accountNetworkErrorMessage()
                    default:
                        return ""
                    }
                } else {
                    return jollaStore.beingOfflineMessage()
                }
            }
            hintText: {
                if (jollaStore.accountState === AccountState.NeedsUpdate) {
                    //% "Settings | Accounts"
                    var link = "<a href='dummy'>" + qsTrId("jolla-store-la-settings_accounts") + "</a>"

                    //: View placeholder hint text shown when there's some problem with the account
                    //: that requires the user to go to settings and sign in again.
                    //: Takes "Settings | Accounts" (jolla-store-la-settings_accounts) as parameter.
                    //: This is done because we're creating programmatically a hyperlink for it.
                    //% "Go to %1 and sign in again"
                    return qsTrId("jolla-store-li-account_needs_update_hint_text").arg(link)
                } else {
                    return ""
                }
            }

            _hintLabel {
                textFormat: Text.StyledText
                linkColor: Theme.primaryColor
                onLinkActivated: settingsDbus.openAccountsPage()
            }
        }
    }

    OfflineButton {}

    DBusInterface {
        id: settingsDbus
        bus: DBus.SessionBus
        service: "com.jolla.settings"
        path: "/com/jolla/settings/ui"
        iface: "com.jolla.settings.ui"

        function openAccountsPage() {
            settingsDbus.call("showAccounts", [])
        }
    }
}
