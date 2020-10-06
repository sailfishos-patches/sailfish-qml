import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0
import com.jolla.settings.system 1.0

AccountSettingsAgent {
    id: root

    property Item settings
    property bool serverSettingsActive
    property bool saveServerSettings

    Component.onCompleted: {
        if (settings === null) {
            settings = settingsComponent.createObject(root)
        }
    }

    initialPage: Page {
        id: settingsPage

        onPageContainerChanged: {
            if (pageContainer == null) {
                root.delayDeletion = true
                settingsDisplay.saveAccount(false, saveServerSettings)
            }
        }

        Component.onDestruction: {
            if (status == PageStatus.Active || root.serverSettingsActive) {
                // app closed while settings are open, so save settings synchronously
                settingsDisplay.saveAccount(true, saveServerSettings)
            }
        }

        SilicaFlickable {
            anchors.fill: parent
            contentHeight: header.height + settingsDisplay.height + Theme.paddingLarge

            StandardAccountSettingsPullDownMenu {
                allowCredentialsUpdate: false
                allowDelete: !root.accountIsReadOnly
                allowDeleteLimited: !root.accountIsLimited

                onAccountDeletionRequested: {
                    root.accountDeletionRequested()
                    pageStack.pop()
                }
                onSyncRequested: {
                    settingsDisplay.saveAccountAndSync(saveServerSettings)
                    saveServerSettings = false
                }

                MenuItem {
                    enabled: settingsDisplay.accountEnabled
                    //: Opens server settings page
                    //% "Server settings"
                    text: qsTrId("accounts-me-server_settings")
                    onClicked: {
                        root.serverSettingsActive = true
                        root.saveServerSettings = true
                        pageStack.animatorPush(root.settings)
                    }
                }
            }

            PageHeader {
                id: header
                title: root.accountsHeaderText
            }

            EmailSettingsDisplay {
                id: settingsDisplay
                anchors.top: header.bottom
                accountManager: root.accountManager
                accountProvider: root.accountProvider
                accountId: root.accountId
                settings: root.settings.settings
                accountIsReadOnly: root.accountIsReadOnly
                accountIsProvisioned: root.accountIsProvisioned

                onAccountSaveCompleted: {
                    root.delayDeletion = false
                }
            }
            VerticalScrollDecorator {}
        }
    }

    Component {
        id: settingsComponent
        Page {
            property bool incomingUsernameEdited: serverConnectionSettings.incomingUsernameEdited
            property bool incomingPasswordEdited: serverConnectionSettings.incomingPasswordEdited
            property bool outgoingUsernameEdited: serverConnectionSettings.outgoingUsernameEdited
            property bool outgoingPasswordEdited: serverConnectionSettings.outgoingPasswordEdited
            property bool checkMandatoryFields: serverConnectionSettings.checkMandatoryFields
            property alias emailAddress: serverConnectionSettings.emailAddress
            property alias serverTypeIndex: serverConnectionSettings.serverTypeIndex
            property alias incomingUsername: serverConnectionSettings.incomingUsername
            property alias incomingPassword: serverConnectionSettings.incomingPassword
            property alias incomingServer: serverConnectionSettings.incomingServer
            property alias incomingSecureConnectionIndex: serverConnectionSettings.incomingSecureConnectionIndex
            property alias incomingPort: serverConnectionSettings.incomingPort
            property alias outgoingUsername: serverConnectionSettings.outgoingUsername
            property alias outgoingPassword: serverConnectionSettings.outgoingPassword
            property alias outgoingServer: serverConnectionSettings.outgoingServer
            property alias outgoingSecureConnectionIndex: serverConnectionSettings.outgoingSecureConnectionIndex
            property alias outgoingPort: serverConnectionSettings.outgoingPort
            property alias outgoingRequiresAuth: serverConnectionSettings.outgoingRequiresAuth
            property alias acceptUntrustedCertificates: serverConnectionSettings.acceptUntrustedCertificates

            property alias settings: serverConnectionSettings

            onPageContainerChanged: {
                if (pageContainer == null) {
                    root.serverSettingsActive = false
                }
            }

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: contentColumn.height
                Column {
                    id: contentColumn
                    width: parent.width
                    enabled: !accountIsReadOnly
                    spacing: Theme.paddingLarge

                    PageHeader {
                        id: header
                        //: Server settings page
                        //% "Server settings"
                        title: qsTrId("accounts-he-server_settings")
                    }

                    DisabledByMdmBanner {
                        id: disabledByMdmBanner
                        active: root.accountIsReadOnly || root.accountIsLimited
			limited: root.accountIsLimited && !root.accountIsReadOnly
                    }

                    EmailCommon {
                        id: serverConnectionSettings
                        editMode: true
                        checkMandatoryFields: true
                        opacity: accountIsReadOnly ? Theme.opacityLow : 1.0
                        accountLimited: root.accountIsLimited
                    }
                }
                VerticalScrollDecorator {}
            }
        }
    }
}
