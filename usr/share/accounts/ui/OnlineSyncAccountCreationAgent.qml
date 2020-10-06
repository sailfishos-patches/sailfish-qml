import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

AccountCreationAgent {
    id: root

    property alias provider: authDialog.accountProvider
    property alias services: authDialog.services

    property alias usernameLabel: authDialog.usernameLabel
    property alias username: authDialog.username
    property alias password: authDialog.password

    property alias extraText: authDialog.extraText
    property alias serverAddress: authDialog.serverAddress
    property alias addressbookPath: authDialog.addressbookPath
    property alias calendarPath: authDialog.calendarPath
    property alias webdavPath: authDialog.webdavPath
    property alias imagesPath: authDialog.imagesPath
    property alias backupsPath: authDialog.backupsPath
    property alias showAdvancedSettings: authDialog.showAdvancedSettings

    property QtObject _accountCreator
    property Page _settingsDialog

    initialPage: OnlineSyncAccountCreationDialog {
        id: authDialog
        acceptDestination: busyComponent
    }

    Component {
        id: busyComponent
        AccountBusyPage {
            onStatusChanged: {
                if (status == PageStatus.Active) {
                    root._createAccount()
                }
            }
        }
    }

    function _createAccount() {
        if (_accountCreator != null) {
            _accountCreator.destroy()
        }
        var props = {
            "provider": provider,
            "services": services,
            "username": authDialog.username,
            "password": authDialog.password,
            "serverAddress": authDialog.serverAddress,
            "addressbookPath": authDialog.addressbookPath,
            "calendarPath": authDialog.calendarPath,
            "webdavPath": authDialog.webdavPath,
            "imagesPath": authDialog.imagesPath,
            "backupsPath": authDialog.backupsPath,
            "ignoreSslErrors": authDialog.ignoreSslErrors,
            "servicesEnabledConfig": authDialog.servicesEnabledConfig
        }
        _accountCreator = accountCreatorComponent.createObject(root, props)
        _accountCreator.start()
    }

    Component {
        id: accountCreatorComponent
        OnlineSyncAccountCreator {
            onSuccess: {
                root._settingsDialog = settingsComponent.createObject(root, {"accountId": newAccountId})
                pageStack.animatorPush(root._settingsDialog)
                root.accountCreated(newAccountId)
            }
            onFailed: {
                console.log("failed to create account:", errorMessage)
                authDialog.acceptDestinationInstance.state = "info"
                authDialog.acceptDestinationInstance.infoExtraDescription = errorMessage
                root.accountCreationError(errorMessage)
            }
            onUpdateCreationStatus: {
                authDialog.acceptDestinationInstance.busyDescription = statusText
            }
        }
    }

    Component {
        id: settingsComponent
        Dialog {
            property alias accountId: settingsDisplay.accountId

            acceptDestination: root.endDestination
            acceptDestinationAction: root.endDestinationAction
            acceptDestinationProperties: root.endDestinationProperties
            acceptDestinationReplaceTarget: root.endDestinationReplaceTarget
            backNavigation: false

            onAccepted: {
                root.delayDeletion = true
                settingsDisplay.saveAccountAndSync()
            }

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: header.height + settingsDisplay.height

                DialogHeader {
                    id: header
                }

                OnlineSyncAccountSettingsDisplay {
                    id: settingsDisplay

                    anchors.top: header.bottom
                    accountManager: root.accountManager
                    accountProvider: root.accountProvider
                    autoEnableAccount: true
                    services: root.services
                    allowCalendarRefresh: false

                    onAccountSaveCompleted: {
                        root.delayDeletion = false
                    }
                }

                VerticalScrollDecorator {}
            }
        }
    }
}
