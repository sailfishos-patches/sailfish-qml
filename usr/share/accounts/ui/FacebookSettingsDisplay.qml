import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

StandardAccountSettingsDisplay {
    id: root

    function _prepareForSave() {
        // The UI only sets the 'download new content' schedule for the calendar profile,
        // so copy this schedule to other relevant non-microblog profiles.
        var calendarSchedule = otherContentSchedule.schedule
        var serviceNames = ["facebook-images"]
        for (var i=0; i<serviceNames.length; i++) {
            var optionsMap = settingsLoader.allSyncOptionsForService(serviceNames[i])
            for (var profileId in optionsMap) {
                var profileSyncOptions = optionsMap[profileId]
                profileSyncOptions.schedule = calendarSchedule
            }
        }

        // make sure facebook-im, facebook-contacts and facebook-microblog services are turned off
        root.account.disableWithService("facebook-im")
        root.account.disableWithService("facebook-contacts")
        root.account.disableWithService("facebook-microblog")
    }

    settingsModified: true
    onAboutToSaveAccount: {
        var needProfileUpdate = false;
        if (settingsLoader.anySyncOptionsModified()
                || (otherContentSchedule.schedule && otherContentSchedule.schedule.modified)
                || (calendarPastSync.syncOptions && calendarPastSync.syncOptions.modified)) {
            needProfileUpdate = true
        }
        _prepareForSave()
        if (needProfileUpdate) {
            settingsLoader.updateAllSyncProfiles()
        }
    }

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
            var profileId = 0
            var calendarOptions = allSyncOptionsForService("facebook-calendars")
            for (profileId in calendarOptions) {
                otherContentSchedule.syncOptions = calendarOptions[profileId]
                calendarPastSync.syncOptions = calendarOptions[profileId]
                break
            }
        }
    }

    SectionHeader {
        //: Options for data to be downloaded from a remote server
        //% "Download"
        text: qsTrId("settings-accounts-la-download_options")
    }

    Column {
        width: parent.width

        Repeater {
            id: syncServicesRepeater
            TextSwitch {
                id: serviceSwitch
                checked: model.enabled
                text: model.displayName
                visible: text.length > 0 && model.serviceName !== "facebook-contacts" && model.serviceName !== "facebook-microblog"
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

    SectionHeader {
        //: Options for data download
        //% "Download details"
        text: qsTrId("settings-accounts-la-download_details")
    }

    SyncScheduleOptions {
        id: otherContentSchedule

        property QtObject syncOptions

        schedule: syncOptions ? syncOptions.schedule : null

        //: Click to show options on how often other content should be downloaded from the server
        //% "Download other content"
        label: qsTrId("settings-accounts-la-download_other_content")
    }

    Loader {
        width: parent.width
        height: item ? item.height : 0
        sourceComponent: (otherContentSchedule.syncOptions
                          && otherContentSchedule.syncOptions.schedule.enabled
                          && otherContentSchedule.syncOptions.schedule.peakScheduleEnabled) ? otherContentPeakOptions : null
        Component {
            id: otherContentPeakOptions
            PeakSyncOptions {
                schedule: otherContentSchedule.syncOptions.schedule
            }
        }
    }

    SyncPastPeriodOptions {
        id: calendarPastSync
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
