import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

StandardAccountSettingsDisplay {
    id: root

    function _prepareForSave() {
        // nothing to do.  Normally we'd set up sync schedules here.
    }

    settingsModified: true
    onAboutToSaveAccount: {
        var needProfileUpdate = false
        if (settingsLoader.anySyncOptionsModified()
                || (feedSchedule.schedule && feedSchedule.schedule.modified)
                || (otherContentSchedule.schedule && otherContentSchedule.schedule.modified)
                || (calendarPastSync.syncOptions && calendarPastSync.syncOptions.modified)) {
            // the otherContentSchedule is shared between the calendar and contacts profiles
            settingsLoader.setSyncOptionsForServiceProfile("vk-contacts", "vk.Contacts", otherContentSchedule.syncOptions)
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

            // load the initial settings, with shared sync schedule options for calendar+contacts
            var profileId = 0
            var microblogOptions = allSyncOptionsForService("vk-microblog")
            for (profileId in microblogOptions) {
                feedSchedule.syncOptions = microblogOptions[profileId]
                break
            }
            var calendarOptions = allSyncOptionsForService("vk-calendars")
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

    SectionHeader {
        //: Options for data download
        //% "Download details"
        text: qsTrId("settings-accounts-la-download_details")
    }

    SyncScheduleOptions {
        id: feedSchedule

        property QtObject syncOptions

        //: Click to show options on how often content feed updates should be fetched from the server
        //% "Download feed updates"
        label: qsTrId("settings-accounts-la-download_feed_updates")
        schedule: syncOptions ? syncOptions.schedule : null
    }

    Loader {
        width: parent.width
        height: item ? item.height : 0
        sourceComponent: (feedSchedule.syncOptions
                          && feedSchedule.syncOptions.schedule.enabled
                          && feedSchedule.syncOptions.schedule.peakScheduleEnabled) ? microblogPeakOptions : null
        Component {
            id: microblogPeakOptions
            PeakSyncOptions {
                schedule: feedSchedule.syncOptions.schedule
            }
        }
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
