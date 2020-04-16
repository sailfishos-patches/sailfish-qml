import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

StandardAccountSettingsDisplay {
    id: root

    property var services: ({})

    property bool _hasEnabledService
    property bool _showCalendarSettings
    property QtObject _sharedOptions // schedule is shared between all services
    property bool _settingsLoaded

    function _loadSettings() {
        if (services.length === 0) {
            return
        }

        // enable the profile schedules if required
        var allSslErrorsIgnored = true
        var hasEnabledService = false
        for (var i = 0; i < services.length; ++i) {
            var service = services[i]
            var serviceEnabled = root.account.isEnabledWithService(service.name)
            var allProfileIds = syncManager.profileIds(account.identifier, service.name)
            var profileId = allProfileIds.length > 0 ? allProfileIds[0] : ""
            var serviceConfig = root.account.configurationValues(service.name)

            allSslErrorsIgnored &= (serviceConfig["ignore_ssl_errors"] === true)
            hasEnabledService |= serviceEnabled

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
        if (serverAddressField.text.length === 0 && serviceConfig.server_address.length > 0) {
            serverAddressField.text = serviceConfig.server_address
        }
        ignoreSslErrors.checked = allSslErrorsIgnored
        _hasEnabledService = hasEnabledService
        _settingsLoaded = true
    }

    settingsModified: true // TODO only set to true when these settings have been modified
    onAboutToSaveAccount: {
        for (var i = 0; i < serviceModel.count; ++i) {
            var serviceData = serviceModel.get(i)
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

    nextFocusItem: serverAddressField

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

    TextField {
        id: serverAddressField

        width: parent.width
        //% "Server address"
        label: qsTrId("components_accounts-la-server_address")

        onTextChanged: {
            if (activeFocus) {
                for (var i = 0; i < root.services.length; ++i) {
                    root.account.setConfigurationValue(root.services[i].name, "server_address", text)
                }
            }
        }

        EnterKey.enabled: text || inputMethodComposing
        EnterKey.iconSource: "image://theme/icon-m-enter-close"
        EnterKey.onClicked: root.focus = true
    }

    TextSwitch {
        id: ignoreSslErrors
        //: Switch to ignore SSL security errors
        //% "Ignore SSL Errors"
        text: qsTrId("components_accounts-la-jabber_ignore_ssl_errors")
    }

    SectionHeader {
        //: Options for data to be synced with a remote server
        //% "Sync"
        text: qsTrId("settings-accounts-la-sync_options")
    }

    TextSwitch {
        id: autoSyncSwitch
        visible: serviceModel.count > 0
        enabled: root._hasEnabledService
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
        enabled: root._hasEnabledService
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
        enabled: root._hasEnabledService
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
        id: serviceSwitchRepeater

        model: serviceModel

        delegate: TextSwitch {
            onCheckedChanged: {
                if (root._settingsLoaded) {
                    serviceModel.setProperty(model.index, "enableWhenSaved", checked)
                }
                if (model.service.serviceType === "caldav") {
                    _showCalendarSettings = checked
                }
            }
            checked: model.enableWhenSaved
            text: AccountsUtil.serviceDisplayNameForService(model.service)

            onClicked: {
                root._hasEnabledService = root.testHasCheckedSwitch(serviceSwitchRepeater)
            }
        }
    }

    OnlineCalendarDisplay {
        id: calendarDisplay
        visible: root._settingsLoaded && root._showCalendarSettings
    }
}
