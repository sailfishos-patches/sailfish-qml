import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0
import com.jolla.sailfisheas 1.0
import "SailfishEasSettings.js" as ServiceSettings

AccountSettingsAgent {
    id: root

    property Item connectionSettingsPage
    property bool serverSettingsActive
    property bool saveConnectionSettings

    Component.onCompleted: {
        if (connectionSettingsPage === null) {
            connectionSettingsPage = connectionSettingsComponent.createObject(root)
        }
    }

    initialPage: Page {
        id: settingsPage

        onPageContainerChanged: {
            if (pageContainer == null) {
                root.delayDeletion = true
                settingsDisplay.saveAccount(false, saveConnectionSettings)
            }
        }

        Component.onDestruction: {
            if (status == PageStatus.Active || root.serverSettingsActive) {
                // app closed while settings are open, so save settings synchronously
               settingsDisplay.saveAccount(true, saveConnectionSettings)
            }
        }

        SilicaFlickable {
            anchors.fill: parent
            contentHeight: header.height + settingsDisplay.height + Theme.paddingLarge

            StandardAccountSettingsPullDownMenu {
                allowCredentialsUpdate: false

                onAccountDeletionRequested: {
                    root.accountDeletionRequested()
                    pageStack.pop()
                }
                onSyncRequested: {
                    settingsDisplay.saveAccountAndSync(saveConnectionSettings)
                    saveConnectionSettings = false
                }

                MenuItem {
                    enabled: settingsDisplay.accountEnabled
                    //: Opens server settings page
                    //% "Edit server settings"
                    text: qsTrId("accounts-me-edit_server_settings")
                    onClicked: {
                        root.serverSettingsActive = true
                        root.saveConnectionSettings = true
                        pageStack.animatorPush(root.connectionSettingsPage)
                    }
                }
            }

            PageHeader {
                id: header
                title: root.accountsHeaderText
            }

            SailfishEasSettingsDisplay {
                id: settingsDisplay
                anchors.top: header.bottom
                accountManager: root.accountManager
                accountProvider: root.accountProvider
                accountId: root.accountId
                connectionSettings: root.connectionSettingsPage.settings

                onAccountSaveCompleted: {
                    root.delayDeletion = false
                }
            }
            VerticalScrollDecorator {}
        }
    }

    Component {
        id: connectionSettingsComponent
        Page {
            property alias emailaddress: activesyncConnectionSettings.emailaddress
            property alias username: activesyncConnectionSettings.username
            property alias password: activesyncConnectionSettings.password
            property alias domain: activesyncConnectionSettings.domain
            property alias server: activesyncConnectionSettings.server
            property alias port: activesyncConnectionSettings.port
            property alias secureConnection: activesyncConnectionSettings.secureConnection
            property alias passwordEdited: activesyncConnectionSettings.passwordEdited
            property alias acceptSSLCertificates: activesyncConnectionSettings.acceptSSLCertificates
            property alias settings: activesyncConnectionSettings

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

                    PageHeader {
                        id: header
                        //: Server settings page
                        //% "Server settings"
                        title: qsTrId("accounts-he-server_settings")
                    }

                    SailfishEasConnectionSettings {
                        id: activesyncConnectionSettings
                        checkMandatoryFields: true
                        editMode: true
                    }
                }
                VerticalScrollDecorator {}
            }
        }
    }
}
