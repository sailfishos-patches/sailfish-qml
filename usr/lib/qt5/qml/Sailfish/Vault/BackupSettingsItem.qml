import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Vault 1.0
import Sailfish.Accounts 1.0

Column {
    id: root

    property int cloudAccountId
    readonly property bool ready: cloudAccountId > 0 && _profileId.length > 0
    property var storageListModel

    property var locale: Qt.locale()
    property var syncOptions
    property var schedule

    property string _profileId

    signal createAccount()

    function selectAccountId(accountId) {
        scheduleStoragePicker.selectAccountId(accountId)
    }

    function reload() {
        if (cloudAccountId <= 0) {
            _profileId = ""
            syncOptions = null
            schedule = null
            return
        }

        _profileId = syncManager.findBackupOperationProfile(cloudAccountId, AccountSyncManager.Backup)
        syncOptions = syncManager.accountSyncOptions(_profileId)
        schedule = syncOptions.schedule

        // Schedule frequency
        if (schedule.longInterval !== AccountSyncSchedule.NoLongInterval) {
            scheduleCombo.currentIndex = 2  // Monthly
            switch (schedule.longInterval) {
            case AccountSyncSchedule.MonthLongInterval:
                monthOptionCombo.currentIndex = 0
                break
            case AccountSyncSchedule.FirstDayOfMonthInterval:
                monthOptionCombo.currentIndex = 1
                break
            case AccountSyncSchedule.LastDayOfMonthInterval:
                monthOptionCombo.currentIndex = 2
                break
            }
        } else if (schedule.days === AccountSyncSchedule.EveryDay) {
            scheduleCombo.currentIndex = 0  // Daily
        } else {
            scheduleCombo.currentIndex = 1  // Weekly
            scheduleDaySelector.reload(schedule.days)
        }

        // Schedule sync time
        scheduleTimeButton.reloadFromTime(schedule.dailySyncTime)

        // Schedule connection options. Default value is WLAN-only.
        connectionCombo.currentIndex = (syncOptions.allowedConnectionTypes & AccountSyncOptions.Cellular) ? 1 : 0
    }

    function _saveChanges() {
        // Schedule frequency
        var longInterval
        switch (scheduleCombo.currentIndex) {
        case 0:
            // Daily
            schedule.enabled = true
            schedule.setDailySyncMode(scheduleTimeButton.time)
            break
        case 1:
            // Weekly
            schedule.enabled = true
            schedule.setDailySyncMode(scheduleTimeButton.time, scheduleDaySelector.selectedDay())
            break
        case 2:
            // Monthly
            schedule.enabled = true
            switch (monthOptionCombo.currentIndex) {
            case 0:
                schedule.setLongIntervalSyncMode(AccountSyncSchedule.MonthLongInterval, scheduleTimeButton.time)
                break
            case 1:
                schedule.setLongIntervalSyncMode(AccountSyncSchedule.FirstDayOfMonthInterval, scheduleTimeButton.time)
                break
            case 2:
                schedule.setLongIntervalSyncMode(AccountSyncSchedule.LastDayOfMonthInterval, scheduleTimeButton.time)
                break
            }
            break
        default:
            break
        }

        if (schedule.enabled) {
            // Schedule connection options
            syncOptions.allowedConnectionTypes = connectionCombo.currentIndex === 1
                    ? (AccountSyncOptions.Wlan | AccountSyncOptions.Cellular)
                    : AccountSyncOptions.Wlan
        }

        _saveSchedule(schedule.enabled)
        reload()
    }

    function _saveSchedule(scheduleEnabled) {
        // Note that when a schedule is disabled, other options are left intact so that settings
        // are maintained when it's re-enabled.

        schedule.enabled = scheduleEnabled

        // Ensure the profile is enabled. (Don't disable the profile when the schedule is disabled,
        // else it cannot be used for manual backups.)
        var profileProperties = scheduleEnabled
                ? { "enabled": "true" }
                : {}
        syncManager.updateProfile(_profileId, profileProperties, syncOptions)
    }

    width: parent.width

    onCloudAccountIdChanged: {
        reload()
    }

    ScheduledBackupStoragePicker {
        id: scheduleStoragePicker

        storageListModel: root.storageListModel

        onStorageClicked: {
            // Disable the previously set schedule
            if (root.cloudAccountId > 0) {
                root._saveSchedule(false)
            }

            root.cloudAccountId = selectedAccountId
            if (root.cloudAccountId > 0) {
                // Save the new schedule
                root._saveSchedule(true)
            }
        }

        onCreateAccount: root.createAccount()
    }

    ComboBox {
        id: scheduleCombo

        //: Setting for changing the frequency of scheduled backups
        //% "Back up"
        label: qsTrId("vault-la-back_up")
        visible: !!root.schedule && root.schedule.enabled

        menu: ContextMenu {
            MenuItem {
                //: Backups will be done daily
                //% "Daily"
                text: qsTrId("vault-me-daily")
                onClicked: root.schedule.enabled = true
                onDelayedClick: root._saveChanges()
            }
            MenuItem {
                //: Backups will be done weekly
                //% "Weekly"
                text: qsTrId("vault-me-weekly")
                onClicked: root.schedule.enabled = true
                onDelayedClick: root._saveChanges()
            }
            MenuItem {
                //: Backups will be done monthly
                //% "Monthly"
                text: qsTrId("vault-me-monthly")
                onClicked: root.schedule.enabled = true
                onDelayedClick: root._saveChanges()
            }
        }
    }

    ComboBox {
        id: monthOptionCombo

        visible: !!root.schedule
                 && root.schedule.enabled
                 && root.schedule.longInterval !== AccountSyncSchedule.NoLongInterval

        //: Select day on which back up should be done
        //% "Day"
        label: qsTrId("vault-la-day")
        menu: ContextMenu {
            MenuItem {
                //: Select to schedule one month between backups
                //% "One month after last backup"
                text: qsTrId("vault-me-one_month_after_last_backup")
                onClicked: root.schedule.enabled = true
                onDelayedClick: root._saveChanges()
            }
            MenuItem {
                //: Select to schedule backups on the first day of each month
                //% "First day of month"
                text: qsTrId("vault-me-first_day_of_month")
                onClicked: root.schedule.enabled = true
                onDelayedClick: root._saveChanges()
            }
            MenuItem {
                //: Select to schedule backups on the last day of each month
                //% "Last day of month"
                text: qsTrId("vault-me-last_day_of_month")
                onClicked: root.schedule.enabled = true
                onDelayedClick: root._saveChanges()
            }
        }
    }

    ComboBox {
        id: scheduleDaySelector

        property int _selectedIndex: 0

        property var _days: [AccountSyncSchedule.Sunday, AccountSyncSchedule.Monday,
            AccountSyncSchedule.Tuesday,
            AccountSyncSchedule.Wednesday, AccountSyncSchedule.Thursday,
            AccountSyncSchedule.Friday, AccountSyncSchedule.Saturday]

        function selectedDay() {
            return _days[_selectedIndex]
        }

        function reload(days) {
            for (var i = 0; i < _days.length; ++i) {
                if ((days & _days[i]) !== 0) {
                    currentIndex = i
                    break
                }
            }
        }

        label: monthOptionCombo.label
        visible: !!root.schedule
                 && root.schedule.enabled
                 && scheduleCombo.currentIndex === 1
        currentIndex: -1

        menu: ContextMenu {
            onActivated: {
                scheduleDaySelector._selectedIndex = index
                root._saveChanges()
            }

            Repeater {
                id: dayRepeater
                model: ListModel {
                    id: dayModel

                    Component.onCompleted: {
                        // js week starts on Sunday
                        for (var day = 0; day < 7; ++day) {
                            append({"day": day, "name": root.locale.dayName(day, Locale.LongFormat)})
                        }
                    }
                }

                MenuItem {
                    text: model.name

                    onClicked: root.schedule.enabled = true
                    onDelayedClick: root._saveChanges()
                }
            }
        }
    }

    ValueButton {
        id: scheduleTimeButton

        property var time: new Date()

        function reload(h, m) {
            time.setHours(h)
            time.setMinutes(m)
            value = Format.formatDate(time, Formatter.TimeValue)
        }

        function reloadFromTime(t) {
            time = t
            value = Format.formatDate(time, Formatter.TimeValue)
        }

        visible: !!root.schedule && root.schedule.enabled

        //: Select time at which backup should be done
        //% "Time"
        label: qsTrId("vault-la-time")

        onClicked: {
            var obj = pageStack.animatorPush("Sailfish.Silica.TimePickerDialog", {
                                                 hour: time.getHours(),
                                                 minute: time.getMinutes()
                                             })
            obj.pageCompleted.connect(function(page) {
                page.accepted.connect(function() {
                    scheduleTimeButton.reload(page.hour, page.minute)
                    root._saveChanges()
                })
            })
        }
    }

    ComboBox {
        id: connectionCombo

        visible: !!root.schedule && root.schedule.enabled

        //: Setting for changing whether backups will be done over WLAN, mobile data connection etc.
        //% "Connection"
        label: qsTrId("vault-la-connection")

        menu: ContextMenu {
            MenuItem {
                //: Backups will only be done over WLAN
                //% "WLAN only"
                text: qsTrId("vault-me-wlan_only")
                onDelayedClick: root._saveChanges()
            }
            MenuItem {
                //: Backups will only be done over either WLAN or mobile data connections, whichever is available
                //% "WLAN or mobile data"
                text: qsTrId("vault-me-wlan_or_mobile_data")
                onDelayedClick: root._saveChanges()
            }
        }
    }

    Connections {
        target: root.storageListModel.cloudAccountModel
        onCountChanged: _findEnabledSchedule()
        Component.onCompleted: _findEnabledSchedule()

        function _findEnabledSchedule() {
            var model = root.storageListModel.cloudAccountModel
            for (var i = 0; i < model.count; ++i) {
                var accountId = model.get(i).accountId
                var profileId = syncManager.findBackupOperationProfile(accountId, AccountSyncManager.Backup)
                if (profileId.length) {
                    var syncOptions = syncManager.accountSyncOptions(profileId)
                    if (syncOptions.schedule.enabled) {
                        target = null
                        scheduleStoragePicker.selectAccountId(accountId)
                        return
                    }
                }
            }
        }
    }

    AccountSyncManager {
        id: syncManager

        onProfileUpdateError: console.warn("Unable to update profile", profileId, ":", errorString)
    }
}
