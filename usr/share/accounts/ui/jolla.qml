import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.accounts 1.0
import org.nemomobile.configuration 1.0

AccountCreationAgent {
    id: root

    property bool wizardMode
    property bool runningFromSettingsApp: true

    // only set wizardMode when config is initially loaded (else it changes once account is
    // created), and don't override value if already set by component owner
    property bool _autoSetWizardMode: true
    onWizardModeChanged: _autoSetWizardMode = false

    Binding {
        target: root
        property: "wizardMode"
        value: !hasCreatedJollaAccountBefore.value
        when: root._autoSetWizardMode
    }

    ConfigurationValue {
        id: hasCreatedJollaAccountBefore
        key: "/apps/jolla-settings/jolla_account_creation_achieved"
    }

    initialPage: JollaAccountSetupDialog {
        wizardMode: root.wizardMode
        runningFromSettingsApp: root.runningFromSettingsApp

        skipDestination: root.endDestination
        skipDestinationAction: root.endDestinationAction
        skipDestinationProperties: root.endDestinationProperties
        skipDestinationReplaceTarget: root.endDestinationReplaceTarget

        onAccountCreated: {
            hasCreatedJollaAccountBefore.value = true
            hasCreatedJollaAccountBefore.sync()
            root.accountCreated(accountId)

            if (!wizardMode) {
                pageStack.animatorReplace(settingsComponent, {"accountId": accountId})
            } else {
                var props = {
                    "runningFromSettingsApp": root.runningFromSettingsApp,
                    "endDestination": root.endDestination,
                    "endDestinationAction": root.endDestinationAction,
                    "endDestinationProperties": root.endDestinationProperties,
                    "endDestinationReplaceTarget": root.endDestinationReplaceTarget
                }
                pageStack.animatorReplace(Qt.resolvedUrl("JollaAccountWizardFlow.qml"), props)
            }
        }

        onAccountCreationError: {
            root.accountCreationError(errorMessage)
        }

        onSkipRequested: {
            root.goToEndDestination()
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
                settingsDisplay.saveAccount()
            }

            Component.onDestruction: {
                if (status == PageStatus.Active && !settingsDisplay.account.enabled) {
                    // jolla account cannot be re-enabled in UI, so ensure it is saved in enabled state
                    // if app is closed while this dialog is open
                    settingsDisplay.account.enabled = true
                    settingsDisplay.saveAccount(true)
                }
            }

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: header.height + settingsDisplay.height + Theme.paddingLarge

                DialogHeader {
                    id: header
                }

                JollaAccountSettingsDisplay {
                    id: settingsDisplay
                    anchors.top: header.bottom
                    accountProvider: root.accountProvider
                    accountManager: root.accountManager
                    accountEnabledReadOnly: true
                    autoEnableAccount: true

                    onAccountSaveCompleted: {
                        root.delayDeletion = false
                    }
                }
            }
        }
    }
}
