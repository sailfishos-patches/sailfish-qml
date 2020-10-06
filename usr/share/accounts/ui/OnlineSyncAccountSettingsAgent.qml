/*
 * Copyright (c) 2013 - 2019 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

AccountSettingsAgent {
    id: root

    property var services: []
    property var sharedScheduleServices: services

    initialPage: Page {
        onPageContainerChanged: {
            if (pageContainer == null && !credentialsUpdater.running) {
                root.delayDeletion = true
                settingsDisplay.saveAccount()
            }
        }

        Component.onDestruction: {
            if (status == PageStatus.Active) {
                // app closed while settings are open, so save settings synchronously
                settingsDisplay.saveAccount(true)
            }
        }

        SilicaFlickable {
            anchors.fill: parent
            contentHeight: header.height + settingsDisplay.height + Theme.paddingLarge

            StandardAccountSettingsPullDownMenu {
                onCredentialsUpdateRequested: {
                    credentialsUpdater.replaceWithCredentialsUpdatePage(root.accountId)
                }
                onAccountDeletionRequested: {
                    root.accountDeletionRequested()
                    pageStack.pop()
                }
                onSyncRequested: {
                    settingsDisplay.saveAccountAndSync()
                }

                MenuItem {
                    //% "Advanced settings"
                    text: qsTrId("components_accounts-la-advanced_settings")

                    onClicked: {
                        pageStack.animatorPush(advancedSettingsDialogComponent, {"title": text})
                    }
                }
            }

            PageHeader {
                id: header
                title: root.accountsHeaderText
            }

            OnlineSyncAccountSettingsDisplay {
                id: settingsDisplay

                anchors.top: header.bottom
                accountManager: root.accountManager
                accountProvider: root.accountProvider
                accountId: root.accountId
                services: root.services
                sharedScheduleServices: root.sharedScheduleServices

                onAccountSaveCompleted: {
                    root.delayDeletion = false
                }
            }

            VerticalScrollDecorator {}
        }

        AccountCredentialsUpdater {
            id: credentialsUpdater
        }
    }

    Component {
        id: advancedSettingsDialogComponent

        OnlineSyncAccountAdvancedSettingsDialog {
            account: settingsDisplay.account
            services: root.services

            onSettingsChanged: {
                settingsDisplay.saveAccount(true)

                // Reload the account settings from the saved values.
                settingsDisplay.reload(settingsDisplay.account.identifier)
            }
        }
    }
}
