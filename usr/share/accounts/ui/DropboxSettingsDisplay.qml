import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

StandardAccountSettingsDisplay {
    id: root

    settingsModified: true // TODO only set to true when these settings have been modified

    StandardAccountSettingsLoader {
        id: settingsLoader
        account: root.account
        accountProvider: root.accountProvider
        accountManager: root.accountManager
        autoEnableServices: root.autoEnableAccount

        onSettingsLoaded: {
            syncServicesRepeater.model = syncServices
            otherServicesDisplay.serviceModel = otherServices

            // load the initial settings, using the first set of sync options as reference
            var dropboxOptions = allSyncOptionsForService("dropbox-sharing")
            for (var profileId in dropboxOptions) {
                dropboxSchedule.syncOptions = dropboxOptions[profileId]
                break
            }
        }
    }

    Column {
        id: syncServicesDisplay
        width: parent.width

        SectionHeader {
            //: Options for data to be downloaded from a remote server
            //% "Download"
            text: qsTrId("settings-accounts-la-download_options")
        }   

        Repeater {
            id: syncServicesRepeater
            TextSwitch {
                id: serviceSwitch
                checked: model.enabled
                text: model.displayName
                visible: text.length > 0
                onCheckedChanged: {
                    if (checked) {
                        root.account.enableWithService(model.serviceName)
                    } else {
                        root.account.disableWithService(model.serviceName)
                    }
                }
            }
        }
    }

    AccountServiceSettingsDisplay {
        id: otherServicesDisplay
        enabled: root.accountEnabled

        onUpdateServiceEnabledStatus: {
            if (enabled) {
                root.account.enableWithService(serviceName)
            } else {
                root.account.disableWithService(serviceName)
            }
        }
    }
}
