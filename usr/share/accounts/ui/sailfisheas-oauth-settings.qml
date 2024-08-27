/*
 * Copyright (C) 2022 Jolla Ltd.
 *
 * License: Proprietary
 */
import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0
import com.jolla.sailfisheas 1.0
import com.jolla.settings.system 1.0
import "SailfishEasSettings.js" as ServiceSettings

AccountSettingsAgent {
    id: root

    property Item connectionSettingsPage
    property bool serverSettingsActive
    property bool saveConnectionSettings

    Component.onCompleted: {
        if (!connectionSettingsPage) {
            connectionSettingsPage = connectionSettingsComponent.createObject(root)
        }
    }

    initialPage: Page {
        onPageContainerChanged: {
            if (pageContainer == null && !credentialsUpdater.running) {
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

        AccountCredentialsUpdater {
            id: credentialsUpdater
        }

        SilicaFlickable {
            anchors.fill: parent
            contentHeight: header.height + settingsDisplay.height + Theme.paddingLarge

            StandardAccountSettingsPullDownMenu {
                allowCredentialsUpdate: root.accountNotSignedIn
                allowDelete: !root.accountIsReadOnly
                allowDeleteLimited: !root.accountIsLimited

                onCredentialsUpdateRequested: credentialsUpdater.replaceWithCredentialsUpdatePage(root.accountId)
                onAccountDeletionRequested: {
                    root.accountDeletionRequested()
                    pageStack.pop()
                }
                onSyncRequested: {
                    settingsDisplay.saveAccountAndTriggerSync(saveConnectionSettings)
                    saveConnectionSettings = false
                }

                MenuItem {
                    visible: !root.accountIsReadOnly
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
                oauthEnabled: true
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
            property alias settings: activesyncConnectionSettings

            onPageContainerChanged: {
                if (pageContainer == null) {
                    root.serverSettingsActive = false
                    if (!credentialsUpdater.running) {
                        root.delayDeletion = true
                        settingsDisplay.saveAccount(false, saveConnectionSettings)
                    }
                }
            }

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: contentColumn.height
                Column {
                    id: contentColumn
                    width: parent.width
                    bottomPadding: Theme.paddingMedium

                    PageHeader {
                        id: header
                        //: Server settings page
                        //% "Server settings"
                        title: qsTrId("accounts-he-server_settings")
                    }

                    DisabledByMdmBanner {
                        id: disabledByMdmBanner
                        active: root.accountIsLimited
                        limited: true
                    }

                    SailfishEasConnectionSettings {
                        id: activesyncConnectionSettings
                        oauthEnabled: true
                        checkMandatoryFields: true
                        editMode: true
                        limitedMode: root.accountIsLimited
                        onCertificateDataSaved: {
                            // increase credentials counter so daemon side knows to reload.
                            // would be saved later, but let's already avoid different settings getting out of sync
                            settingsDisplay.increaseCredentialsCounter()
                            settingsDisplay.saveAccount(false, true)
                        }
                    }
                }
                VerticalScrollDecorator {}
            }
        }
    }
}
