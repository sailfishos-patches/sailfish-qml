import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

StandardAccountSettingsDisplay {
    id: root

    property var services: ({})

    property bool _hasEnabledService
    property bool _allServicesInitiallyEnabled
    property bool _showCalendarSettings
    property QtObject _sharedOptions // schedule is shared between all services
    property bool _settingsLoaded

    function _ignoreSslErrors(service) {
        return root.account.configurationValues(service.name)["ignore_ssl_errors"] === true
    }

    function _loadSettings() {
        if (services.length === 0) {
            return
        }

        // enable the profile schedules if required
        var allSslErrorsIgnored = true
        for (var i = 0; i < services.length; ++i) {
            var service = services[i]
            var serviceEnabled = root.account.isEnabledWithService(service.name)
            var allProfileIds = syncManager.profileIds(account.identifier, service.name)
            var profileId = allProfileIds.length > 0 ? allProfileIds[0] : ""
            allSslErrorsIgnored &= _ignoreSslErrors(service)
            _allServicesInitiallyEnabled &= serviceEnabled

            if (profileId.length > 0) {
                if (service.serviceType === "caldav") {
                    calendarDisplay.profileId = profileId
                    _showCalendarSettings = serviceEnabled
                }
                if (!_sharedOptions) {
                    _sharedOptions = syncManager.accountSyncOptions(profileId)
                    autoSyncSwitch.checked = _sharedOptions.automaticSyncEnabled
                }
            }
            var modelData = {
                "service": service,
                "initiallyEnabled": serviceEnabled,
                "enableWhenSaved": serviceEnabled,
                "profileId": profileId

            }
            serviceModel.append(modelData)
        }
        ignoreSslErrors.checked = allSslErrorsIgnored
        _settingsLoaded = true
    }

    settingsModified: true // TODO only set to true when these settings have been modified
    onAboutToSaveAccount: {
        // If the schedule is enabled but one of the services is disabled,
        // then we need to disable the schedule while saving the schedule for
        // the disabled service, and then possibly re-enable it when saving the
        // schedule for the enabled service.

        for (var i = 0; i < serviceModel.count; ++i) {
            var serviceData = serviceModel.get(i)
            if (_sharedOptions != null && _sharedOptions.schedule != null) {
                _sharedOptions.schedule.enabled &= serviceData.enableWhenSaved
            }
            var propertiesObject = { "enabled": serviceData.enableWhenSaved ? "true" : "false" }
            syncManager.updateProfile(serviceData.profileId, propertiesObject, _sharedOptions)

            if (serviceData.enableWhenSaved) {
                root.account.enableWithService(serviceData.service.name)
            } else {
                root.account.disableWithService(serviceData.service.name)
            }

            root.account.setConfigurationValue(serviceData.service.name, "ignore_ssl_errors", ignoreSslErrors.checked)
        }

        if (calendarDisplay.profileId !== 0) {
            calendarDisplay.applyChanges(account)
        }
    }

    ListModel {
        id: serviceModel
    }

    AccountSyncManager {
        id: syncManager
    }

    Connections {
        target: root.account
        onStatusChanged: {
            if (root.account.status == Account.Initialized) {
                root._loadSettings()
            }
        }
    }

    TextSwitch {
        id: ignoreSslErrors
        //: Switch to ignore SSL security errors
        //% "Ignore SSL Errors"
        text: qsTrId("components_accounts-la-jabber_ignore_ssl_errors")
    }

    TextSwitch {
        id: autoSyncSwitch
        visible: serviceModel.count > 0
        onCheckedChanged: {
            if (root._sharedOptions) {
                if (root._sharedOptions.automaticSyncEnabled != checked) {
                    root._sharedOptions.automaticSyncEnabled = checked
                }
            }
        }
        //: Switch which enables user to enable or disable "automatic synchronization" option
        //% "Sync automatically"
        text: qsTrId("settings-accounts-la-automatic_sync_enabled")
        //: Switch providing setting to enable or disable "automatic synchronization" option
        //% "Sync account when data on the device changes"
        description: qsTrId("settings-accounts-la-sync_account_when_device_data_changes")
    }

    ComboBox {
        id: syncOptionCombo
        visible: serviceModel.count > 0
        label: qsTrId("settings-accounts-la-sync")

        menu: ContextMenu {
            MenuItem {
                text: qsTrId("settings-accounts-me-to_device_only")
                onClicked: {
                    _sharedOptions.direction = AccountSyncOptions.OneWayToDevice
                }
            }
            MenuItem {
                text: qsTrId("settings-accounts-me-two_way_sync")
                onClicked: {
                    _sharedOptions.direction = AccountSyncOptions.TwoWaySync
                }
            }
        }

        Binding {
            when: _sharedOptions != null
            target: syncOptionCombo
            property: "currentIndex"
            value: _sharedOptions != null && _sharedOptions.direction == AccountSyncOptions.TwoWaySync ? 1 : 0
        }
    }

    SyncScheduleOptions {
        id: scheduleOptions
        isSync: true
        schedule: root._sharedOptions ? root._sharedOptions.schedule : null
        visible: serviceModel.count > 0
    }

    Loader {
        width: parent.width
        height: item ? item.height : 0
        active: root._settingsLoaded
                && root._hasEnabledService
                && root._sharedOptions
                && root._sharedOptions.schedule.enabled
                && root._sharedOptions.schedule.peakScheduleEnabled

        sourceComponent: Component {
            PeakSyncOptions {
                schedule: root._sharedOptions.schedule
            }
        }
    }

    SectionHeader {
        //: Section header under which the user can toggle select various services to enable/disable
        //% "Services"
        text: qsTrId("settings_accounts-la-onlinesync_services")
    }

    Repeater {
        model: serviceModel

        delegate: TextSwitch {
            onCheckedChanged: {
                root._hasEnabledService |= checked
                if (root._settingsLoaded) {
                    serviceModel.setProperty(model.index, "enableWhenSaved", checked)
                }
                if (model.service.serviceType === "caldav") {
                    _showCalendarSettings = checked
                }
                // if services were disabled and got enabled, enable also default schedule
                if (!root._allServicesInitiallyEnabled && checked
                        && _sharedOptions != null
                        && _sharedOptions.schedule != null) {
                    scheduleOptions.setInterval(AccountSyncSchedule.TwiceDailyInterval)
                }
            }
            checked: model.enableWhenSaved
            text: model.service.displayName
        }
    }

    OnlineCalendarDisplay {
        id: calendarDisplay
        visible: root._settingsLoaded && root._showCalendarSettings
    }
}
