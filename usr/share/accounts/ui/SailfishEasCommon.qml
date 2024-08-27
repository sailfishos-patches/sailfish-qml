import QtQuick 2.6
import Sailfish.Silica 1.0
import com.jolla.sailfisheas 1.0
import com.jolla.settings.accounts 1.0
import Nemo.Configuration 1.0
import org.nemomobile.systemsettings 1.0

Column {
    id: commonSettings

    property alias mail: mailSwitch.checked
    property alias contacts: contactsSwitch.checked
    property bool contacts2WaySync
    property alias calendar: calendarSwitch.checked
    property alias pastTimeEmailIndex: syncOldMessagesInterval.currentIndex
    property alias pastTimeCalendarIndex: syncOldEventsInterval.currentIndex
    property alias conflictsIndex: conflictsSolvingStrategy.currentIndex
    property alias provision: provisionSwitch.checked
    property alias signatureEnabled: signatureEnabledSwitch.checked
    property alias signature: signatureField.text
    property bool isNewAccount
    property string syncPolicy

    property QtObject syncScheduleOptions

    property bool _changing2WaySync

    function setSyncPolicy(newPolicy) {
        if (folderSyncSettings.item) {
            folderSyncSettings.item.setPolicy(newPolicy)
        }
    }

    width: parent.width

    onContacts2WaySyncChanged: {
        if (!_changing2WaySync) {
            contactsSyncDirectionCombo.currentIndex = contacts2WaySync ? 1 : 0
        }
    }

    OofSettings {
        id: oofSettings

        onSendSettingsCompleted: {
            oofSyncLabel.error = !success
        }
        // clear error state when out of screen
        onRetrieveOofSettingsCompleted: {
            oofSyncLabel.error = false
        }

    }

    SectionHeader {
        //% "Email details"
        text: qsTrId("settings-accounts-la-details_email")
    }

    TextSwitch {
        id: signatureEnabledSwitch
        checked: true
        //: Include signature in emails
        //% "Include signature"
        text: qsTrId("settings-accounts-la-include_email_signature")
    }

    TextArea {
        id: signatureField
        width: parent.width
        textLeftMargin: Theme.itemSizeExtraSmall
        //: Placeholder text for signature text area
        //% "Write signature here"
        placeholderText: qsTrId("settings-accounts-ph-email_signature")
        text: {
            if (settingsConf.default_signature_translation_id && settingsConf.default_signature_translation_catalog) {
                var translated = Format.trId(settingsConf.default_signature_translation_id, settingsConf.default_signature_translation_catalog)
                if (translated && translated != settingsConf.default_signature_translation_id)
                    return translated
            }

            //: Default signature. %1 is an operating system name without the OS suffix
            //% "Sent from my %1 device"
            return qsTrId("settings_email-la-email_default_signature").arg(aboutSettings.baseOperatingSystemName)
        }
    }

    Column {
        width: parent.width
        visible: !isNewAccount
        bottomPadding: Theme.paddingMedium

        SectionHeader {
            //% "Automatic replies"
            text: qsTrId("settings-accounts-la-oof_header")
        }

        Label {
            //% "Use automatic replies to notify others that you are out of the office, on vacation, "
            //% "or otherwise not available to respond on email."
            text: qsTrId("components_accounts_la-oof_description")
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            wrapMode: Text.Wrap
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeSmall
        }

        Item {
            width: 1
            height: Theme.paddingLarge
            visible: oofSyncLabel.visible
        }

        BusyIndicator {
            size: BusyIndicatorSize.Small
            anchors.horizontalCenter: parent.horizontalCenter
            running: oofSettings.state == OofSettings.Setting
            visible: running
        }

        Label {
            id: oofSyncLabel

            // TODO: might be nice to allow retry if sync to server fails
            property bool error

            text: error
                  ? //% "Error synchronizing state to server"
                    qsTrId("components_accounts-la-error-synchronizing_to_server")
                  : //% "Synchronizing..."
                    qsTrId("components_accounts_la-oof_synchronizing")
            visible: oofSettings.state == OofSettings.Setting || error
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            wrapMode: Text.Wrap
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeSmall
            horizontalAlignment: Text.AlignHCenter
        }

        Item {
            width: 1
            height: Theme.paddingLarge
        }

        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            //% "Modify"
            text: qsTrId("components_accounts-bt-oof_edit_settings")
            enabled: oofSettings.state == OofSettings.Idle
            onClicked: {
                pageStack.animatorPush(Qt.resolvedUrl("SailfishEasOofSettingsDialog.qml"),
                                       { "account": account, oofSettings: oofSettings })
            }
        }
    }

    SectionHeader {
        //: Options for data to be synced with a remote server
        //% "Sync"
        text: qsTrId("settings-accounts-la-sync_options")
    }

    TextSwitch {
        id: calendarSwitch
        checked: true
        //: Enables calendar sync
        //% "Calendar"
        text: qsTrId("components_accounts-la-activesync_calendar")
    }

    TextSwitch {
        id: contactsSwitch
        checked: true
        //: Enables contacts sync
        //% "Contacts"
        text: qsTrId("components_accounts-la-activesync_contacts")
    }

    ComboBox {
        id: contactsSyncDirectionCombo
        visible: contactsSwitch.checked

        //% "Sync"
        label: qsTrId("settings-accounts-la-sync")
        labelMargin: Theme.paddingLarge*3

        menu: ContextMenu {
            MenuItem {
                //: Sync data to the device only, do not upload any data
                //% "To device only"
                text: qsTrId("settings-accounts-me-to_device_only")
                onClicked: {
                    _changing2WaySync = true
                    commonSettings.contacts2WaySync = false
                    _changing2WaySync = false
                }
            }
            MenuItem {
                //: Two-way sync. Data will downloaded as well as uploaded.
                //% "2-ways"
                text: qsTrId("settings-accounts-me-two_way_sync")
                onClicked: {
                    _changing2WaySync = true
                    commonSettings.contacts2WaySync = true
                    _changing2WaySync = false
                }
            }
        }
    }

    TextSwitch {
        id: mailSwitch
        checked: true
        //: Enables email sync
        //% "Email"
        text: qsTrId("components_accounts-la-activesync_mail")
    }

    SyncScheduleOptions {
        //: Click to show options on how often sync happens
        //% "Sync schedule"
        label: qsTrId("scomponents_accounts-la-activesync-sync_schedule")
        schedule: syncScheduleOptions ? syncScheduleOptions.schedule : null
        isAlwaysOn: syncScheduleOptions ? syncScheduleOptions.syncExternallyEnabled : false
        showAlwaysOn: true
        intervalModel: EmailIntervalListModel {}

        onAlwaysOnChanged: {
            syncScheduleOptions.syncExternallyEnabled = state
        }
    }

    Loader {
        width: parent.width
        height: item ? item.height : 0
        sourceComponent: (syncScheduleOptions
                          && syncScheduleOptions.schedule.enabled
                          && syncScheduleOptions.schedule.peakScheduleEnabled) ? peakOptions : null
        Component {
            id: peakOptions
            PeakSyncOptions {
                schedule: syncScheduleOptions.schedule
                showAlwaysOn: true
                intervalModel: EmailOffPeakIntervalListModel {}
                offPeakIntervalModel: EmailOffPeakIntervalListModel {}
            }
        }
    }

    SectionHeader {
        //: Options for general content sync
        //% "Content sync"
        text: qsTrId("components_accounts-activesync-la-content_sync")
    }

    ComboBox {
        id: syncOldMessagesInterval
        //: Sync interval for old emails
        //% "Sync old emails"
        label: qsTrId("components_accounts-la-activesync_sync-old-emails")
        currentIndex: 0
        onClicked: {
            commonSettings.move.enabled = false
        }

        menu: ContextMenu {
            MenuItem {
                //: 1 day interval
                //% "1 day"
                text: qsTrId("components_accounts-me-activesync_sync-1-day")
            }
            MenuItem {
                //: 3 days interval
                //% "3 days"
                text: qsTrId("components_accounts-me-activesync_sync-3-day")
            }
            MenuItem {
                //: 1 week interval
                //% "1 week"
                text: qsTrId("components_accounts-me-activesync_sync-1-week")
            }
            MenuItem {
                //: 2 weeks interval
                //% "2 weeks"
                text: qsTrId("components_accounts-me-activesync_sync-2-weeks")
            }
            MenuItem {
                //: 1 month interval
                //% "1 month"
                text: qsTrId("components_accounts-me-activesync_sync-1-month")
            }
        }
    }

    ComboBox {
        id: syncOldEventsInterval
        //: Sync interval for old events
        //% "Sync old events"
        label: qsTrId("components_accounts-la-activesync_sync-old-events")
        currentIndex: 0
        onClicked: {
            commonSettings.move.enabled = false
        }

        menu: ContextMenu {
            MenuItem {
                text: qsTrId("components_accounts-me-activesync_sync-2-weeks")
            }
            MenuItem {
                text: qsTrId("components_accounts-me-activesync_sync-1-month")
            }
            MenuItem {
                //: 3 months interval
                //% "3 months"
                text: qsTrId("components_accounts-me-activesync_sync-3-months")
            }
            MenuItem {
                //: 6 months interval
                //% "6 months"
                text: qsTrId("components_accounts-me-activesync_sync-6-months")
            }
            MenuItem {
                //: All events
                //% "All events"
                text: qsTrId("components_accounts-me-activesync_sync-all-events")
            }
        }
    }

    Loader {
        // FolderSyncSettings availability depends on email packages being installed
        id: folderSyncSettings
        width: parent.width
        source: "FolderSyncSettings.qml"
        onLoaded: {
            item.accountId = Qt.binding(function() { return root.accountId })
            item.active = Qt.binding(function() { return !root.isNewAccount && mailSwitch.checked })
            item.setPolicy(commonSettings.syncPolicy)
        }

        Connections {
            target: folderSyncSettings.item
            onPolicyChanged: commonSettings.syncPolicy = folderSyncSettings.item.policy
        }
    }



    SectionHeader {
        //% "Advanced settings"
        text: qsTrId("components_accounts-activesync-la-advanced_settings")
    }

    ComboBox {
        id: conflictsSolvingStrategy
        //: Rules for solving sync conflicts
        //% "Resolve conflicts"
        label: qsTrId("components_accounts-la-activesync_sync-resolve_conflicts")
        currentIndex: 0
        onClicked: {
            commonSettings.move.enabled = false
        }

        menu: ContextMenu {
            MenuItem {
                //% "Priority to server"
                text: qsTrId("components_accounts-me-activesync_sync-conflicts-server")
            }
            MenuItem {
                //% "Priority to device"
                text: qsTrId("components_accounts-me-activesync_sync-conflicts-device")
            }
        }
    }

    TextSwitch {
        id: provisionSwitch
        checked: true
        //: Inform the server that device can insure requested provision settings (device lock, ...)
        //% "Provisioning"
        text: qsTrId("components_accounts-la-activesync_provisioning")
        //: Description informing the user about provisioning
        //% "When enabled, the device and server will exchange information to confirm if the device meets the server requirements."
        description: qsTrId("components_accounts-la-activesync_provisioning_description")
    }

    move: Transition {
        enabled: false
        FadeAnimation { properties: "x,y" }
    }

    Component {
        id: peakIntervalsMenuComponent
        ContextMenu {
            MenuItem {
                //% "Always up-to-date"
                text: qsTrId("components_accounts-me-activesync_peak-always-uptodate")
            }
            MenuItem {
                //: 15 minutes interval
                //% "Every 15 minutes"
                text: qsTrId("components_accounts-me-activesync_peak-every-15-minutes")
            }
            MenuItem {
                //: 30 minutes interval
                //% "Every 30 minutes"
                text: qsTrId("components_accounts-me-activesync_peak-every-30-minutes")
            }
            MenuItem {
                //: 1 hour interval
                //% "Every hour"
                text: qsTrId("components_accounts-me-activesync_peak-every-hour")
            }
            MenuItem {
                //: 2 hours interval
                //% "Every 2 hours"
                text: qsTrId("components_accounts-me-activesync_peak-every-2-hours")
            }
            MenuItem {
                //: 12 hours interval
                //% "Twice a day"
                text: qsTrId("components_accounts-me-activesync_peak-twice-a-day")
            }
            MenuItem {
                //: 24 hours interval
                //% "Once a day"
                text: qsTrId("components_accounts-me-activesync_peak-once-a-day")
            }
            MenuItem {
                //: Only manual sync
                //% "Manually"
                text: qsTrId("components_accounts-me-activesync_peak-manually")
            }
        }
    }

    ConfigurationGroup {
        id: settingsConf

        path: "/apps/jolla-settings"

        property string default_signature_translation_id
        property string default_signature_translation_catalog
    }

    AboutSettings {
        id: aboutSettings
    }
}
