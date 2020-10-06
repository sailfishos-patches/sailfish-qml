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

StandardAccountSettingsDisplay {
    id: root

    property var services: []
    property var sharedScheduleServices: services
    property bool allowCalendarRefresh: true

    property bool _calendarServiceEnabled
    property QtObject _sharedOptions
    property bool _settingsLoaded
    property bool _cardDavAndCalDavOnly

    function _loadSettings() {
        serviceModel.clear()
        if (services.length === 0) {
            return
        }

        // enable the profile schedules if required
        var allSslErrorsIgnored = true
        var hasEnabledService = false
        var cardDavAndCalDavOnly = true
        for (var i = 0; i < services.length; ++i) {
            var service = services[i]
            var serviceEnabled = root.account.isEnabledWithService(service.name)
            var allProfileIds = syncManager.profileIds(account.identifier, service.name)
            var profileId = allProfileIds.length > 0 ? allProfileIds[0] : ""
            var serviceConfig = root.account.configurationValues(service.name)
            var useSharedSchedule = _findSharedScheduleService(service.name) != null

            allSslErrorsIgnored &= (serviceConfig["ignore_ssl_errors"] === true)
            hasEnabledService |= serviceEnabled

            if (profileId.length > 0) {
                if (service.serviceType === "caldav") {
                    root._calendarServiceEnabled = serviceEnabled
                }
                if (!_sharedOptions && useSharedSchedule) {
                    _sharedOptions = syncManager.accountSyncOptions(profileId)
                    autoSyncSwitch.checked = _sharedOptions.automaticSyncEnabled
                }
            }
            var modelData = {
                "service": service,
                "initiallyEnabled": serviceEnabled,
                "enableWhenSaved": serviceEnabled,
                "profileId": profileId,
                "iconName": service.iconName,
                "description": AccountsUtil.serviceDescription(service, accountProvider.displayName, accountProvider.name),
                "useSharedSchedule": useSharedSchedule,
            }
            serviceModel.append(modelData)

            if (service.serviceType !== "caldav" && service.serviceType !== "carddav") {
                cardDavAndCalDavOnly = false
            }
        }
        if (serverAddressField.text.length === 0 && !!serviceConfig.server_address) {
            serverAddressField.text = serviceConfig.server_address
        }
        ignoreSslErrors.checked = allSslErrorsIgnored
        _cardDavAndCalDavOnly = cardDavAndCalDavOnly
        _settingsLoaded = true
    }

    function _updateCalendars(service, calendarSwitch) {
        // Save changes, else calendar modifications will overwrite current page's modifications.
        saveAccount(true)

        var calendarConfig = account.configurationValues(service.name)
        var props = {
            "account": account,
            "serviceName": service.name,
            "serverAddress": calendarConfig["server_address"],
            "calendarPath": calendarConfig["calendar_path"]
        }

        var obj = pageStack.animatorPush(Qt.resolvedUrl("OnlineCalendarUpdatePage.qml"), props)
        obj.pageCompleted.connect(function(page) {
            page.finished.connect(function(success) {
                // Reload, else any modifications on the settings page will overwrite
                // the new calendar additions.
                if (success) {
                    root.reload(root.accountId)
                    pageStack.pop()
                } else {
                    calendarSwitch.checked = false
                }
            })
        })
    }

    function _findService(name) {
        for (var i = 0; i < root.services.length; ++i) {
            if (root.services[i].name === name) {
                return root.services[i]
            }
        }
        return null
    }

    function _findSharedScheduleService(name) {
        for (var i = 0; i < root.sharedScheduleServices.length; ++i) {
            if (root.sharedScheduleServices[i].name === name) {
                return root.sharedScheduleServices[i]
            }
        }
        return null
    }

    settingsModified: true // TODO only set to true when these settings have been modified
    onAboutToSaveAccount: {
        for (var i = 0; i < serviceModel.count; ++i) {
            var serviceData = serviceModel.get(i)
            if (serviceData.useSharedSchedule) {
                var propertiesObject = { "enabled": serviceData.enableWhenSaved ? "true" : "false" }
                syncManager.updateProfile(serviceData.profileId, propertiesObject, _sharedOptions)
            }

            if (serviceData.enableWhenSaved) {
                root.account.enableWithService(serviceData.service.name)
            } else {
                root.account.disableWithService(serviceData.service.name)
            }

            root.account.setConfigurationValue(serviceData.service.name, "ignore_ssl_errors", ignoreSslErrors.checked)
        }

        if (calendarDisplay.accountId === root.accountId) {
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
        text: _cardDavAndCalDavOnly
                //: Options for data to be synced with a remote server
                //% "Sync"
              ? qsTrId("settings-accounts-la-sync_options")
                //: Sync options for calendars and contacts
                //% "Calendars and Contacts"
              : qsTrId("settings-accounts-la-sync_options_calendars_contacts")
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

    TextSwitch {
        id: autoSyncSwitch

        visible: serviceModel.count > 0
        enabled: _sharedOptions != null
                 && _sharedOptions.direction !== AccountSyncOptions.OneWayToDevice
        onCheckedChanged: {
            if (root._sharedOptions) {
                if (root._sharedOptions.automaticSyncEnabled !== checked) {
                    root._sharedOptions.automaticSyncEnabled = checked
                }
            }
        }
        //: If selected, content changes on device are automatically synchronized to the server
        //% "Sync device changes automatically"
        text: qsTrId("settings-accounts-la-sync_device_changes_automatically")
        //: If selected, content changes on device are automatically synchronized to the server
        //% "Sync whenever relevant content on the device is changed"
        description: qsTrId("settings-accounts-la-sync_when_relevant_content_on_device_changed")
    }

    SectionHeader {
        //: Options for data sync
        //% "Content sync"
        text: qsTrId("settings-accounts-la-content_sync")
        visible: !root._cardDavAndCalDavOnly
    }

    SyncScheduleOptions {
        id: scheduleOptions

        schedule: root._sharedOptions ? root._sharedOptions.schedule : null
        visible: serviceModel.count > 0

        description: {
            if (root._cardDavAndCalDavOnly) {
                return ""
            }
            var serviceNames = []
            for (var i = 0; i < root.sharedScheduleServices.length; ++i) {
                var service = _findService(root.sharedScheduleServices[i].name)
                if (service) {
                    serviceNames.push(service.displayName)
                }
            }
            //: Lists the services to which this option applies. %1 = comma-separated list of service names
            //% "For %1"
            return qsTrId("settings-accounts-la-for_sync_schedule_services").arg(serviceNames.join(Format.listSeparator))
        }
    }

    Loader {
        width: parent.width
        height: item ? item.height : 0
        active: root._settingsLoaded
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

        delegate: IconTextSwitch {
            id: serviceSwitch

            onCheckedChanged: {
                if (root._settingsLoaded) {
                    serviceModel.setProperty(model.index, "enableWhenSaved", checked)
                }
                if (model.service.serviceType === "caldav") {
                    root._calendarServiceEnabled = checked

                    if (checked && !calendarDisplay.valid) {
                        root._updateCalendars(model.service, serviceSwitch)
                    }
                }
            }

            checked: model.enableWhenSaved
            text: AccountsUtil.serviceDisplayNameForService(model.service)
            icon.source: model.iconName
            description: model.description
            automaticCheck: false

            onClicked: {
                if (checked && AccountsUtil.countCheckedSwitches(serviceSwitchRepeater) === 1) {
                    minimumServiceEnabledNotification.publish()
                    return
                }
                checked = !checked
            }
        }
    }

    OnlineCalendarDisplay {
        id: calendarDisplay

        accountId: root.accountId
        visible: valid
        enabled: root._calendarServiceEnabled
        opacity: enabled ? 1.0 : Theme.opacityLow

        Item {
            width: 1
            height: Theme.paddingLarge
            visible: root.allowCalendarRefresh
        }

        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.allowCalendarRefresh

            //% "Update calendars"
            text: qsTrId("components_accounts-la-update_calendars")

            onClicked: {
                for (var i = 0; i < serviceSwitchRepeater.count; ++i) {
                    var item = serviceSwitchRepeater.itemAt(i)
                    if (!!item) {
                        var service = serviceModel.get(i).service
                        if (service.serviceType === "caldav") {
                            _updateCalendars(service, item)
                            return
                        }
                    }
                }
                console.log("Cannot find caldav service!")
            }
        }
    }

    MinimumServiceEnabledNotification {
        id: minimumServiceEnabledNotification
    }
}
