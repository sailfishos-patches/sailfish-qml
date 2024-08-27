import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0
import Nemo.Configuration 1.0

StandardAccountSettingsDisplay {
    id: root

    property bool _hasEnabledService

    settingsModified: true
    onAboutToSaveAccount: {
        if (settingsLoader.anySyncOptionsModified()
                || (feedSchedule.syncOptions && feedSchedule.syncOptions.modified)) {
            // ensure that we set the same sync schedule for notifications as for posts.
            var twitterSyncOptions = settingsLoader.allSyncOptionsForService("twitter-microblog")
            var notificationsOptions
            var postsOptions
            for (var profileId in twitterSyncOptions) {
                if (profileId.indexOf("twitter.Notifications") >= 0) {
                    notificationsOptions = twitterSyncOptions[profileId]
                } else if (profileId.indexOf("twitter.Posts") >= 0) {
                    postsOptions = twitterSyncOptions[profileId]
                }
            }
            notificationsOptions.schedule = postsOptions.schedule
            settingsLoader.updateAllSyncProfiles()
        }
        if (eventsSyncSwitch.checked !== root.account.configurationValues("")["FeedViewAutoSync"]) {
            root.account.setConfigurationValue("", "FeedViewAutoSync", eventsSyncSwitch.checked)
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
            var microblogOptions = allSyncOptionsForService("twitter-microblog")
            for (var profileId in microblogOptions) {
                if (profileId.indexOf("twitter.Posts") >= 0) {
                    feedSchedule.syncOptions = microblogOptions[profileId]
                }
            }

            var autoSync = root.account.configurationValues("")["FeedViewAutoSync"]
            var isNewAccount = root.autoEnableAccount
            eventsSyncSwitch.checked = (isNewAccount || autoSync === true)
        }
    }

    SectionHeader {
        //: Options for data to be downloaded from a remote server
        //% "Download"
        text: qsTrId("settings-accounts-la-download_options")
    }

    Column {
        id: syncServicesDisplay
        width: parent.width

        Repeater {
            id: syncServicesRepeater

            TextSwitch {
                id: serviceSwitch

                checked: model.enabled
                text: model.displayName
                onCheckedChanged: {
                    if (checked) {
                        root.account.enableWithService(model.serviceName)
                    } else {
                        root.account.disableWithService(model.serviceName)
                    }
                    root._hasEnabledService = AccountsUtil.countCheckedSwitches(syncServicesRepeater) > 0
                }
            }
        }
    }

    SyncScheduleOptions {
        id: feedSchedule

        property QtObject syncOptions

        intervalModel: IntervalListModel {
            Component.onCompleted: {
                insert(0, {"interval": AccountSyncSchedule.Every5Minutes})
            }
        }

        schedule: syncOptions ? syncOptions.schedule : null
        enabled: root._hasEnabledService
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

    TextSwitch {
        id: eventsSyncSwitch

        //% "Sync tweets view automatically"
        text: qsTrId("settings-accounts-la-twitter_feed_auto_sync_title")
        //% "Fetch new tweets periodically when browsing Events Twitter feed."
        description: qsTrId("settings-accounts-la-twitter_feed_auto_sync_description")
        enabled: root._hasEnabledService

        onCheckedChanged: {
            autoSyncConf.value = checked
        }
    }

    // notify lipstick of the configuration change since account configuration changes don't
    // emit signals
    ConfigurationValue {
        id: autoSyncConf
        key: "/desktop/lipstick-jolla-home/events/auto_sync_feeds/" + root.account.identifier
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
