/*
 * Copyright (c) 2014 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0
import Nemo.Configuration 1.0
import org.nemomobile.systemsettings 1.0

StandardAccountSettingsDisplay {
    id: root

    property QtObject _settingsLoader
    property QtObject _contactSyncOptionsToLoad
    property bool _emailAvailable
    property bool _calendarOrContactServiceEnabled
    property bool _gmailServiceEnabled
    property bool isNewAccount

    // email settings
    property bool _signatureEnabled
    property string _signature
    property string _yourName
    property bool _pushCapable

    function _saveEmailDetails() {
        account.setConfigurationValue("google-gmail", "signatureEnabled", _signatureEnabled)
        account.setConfigurationValue("google-gmail", "signature", _signature)
        account.setConfigurationValue("google-gmail", "fullName", _yourName)

        // check if is push capable and add default folder (Inbox)
        if (_pushCapable) {
            account.setConfigurationValue("google-gmail", "imap4/pushFolders", "INBOX")
        }

        if (folderSyncSettings.item) {
            account.setConfigurationValue("", "folderSyncPolicy", folderSyncSettings.item.policy)
        }
    }

    settingsModified: true
    onAboutToSaveAccount: {
        if (_emailAvailable) {
            _saveEmailDetails()
        }
        if (settingsLoader.anySyncOptionsModified()
                || (emailSchedule.syncOptions && emailSchedule.syncOptions.modified)) {
            settingsLoader.updateAllSyncProfiles()
        }
    }

    function _enableAutoSync(serviceName, enable) {
        var options = settingsLoader.allSyncOptionsForService(serviceName)
        for (var profileId in options) {
            options[profileId].schedule.enabled = enable
            options[profileId].automaticSyncEnabled = enable
        }
    }

    function _populateEmailDetails() {
        var serviceSettings = account.configurationValues("google-gmail")
        var accountGeneralSettings = account.configurationValues("")
        var signature = serviceSettings["signature"]
        if (signature) {
            signatureField.text = signature
        }
        signatureEnabledSwitch.checked = serviceSettings["signatureEnabled"]
        root._signatureEnabled = signatureEnabledSwitch.checked

        var fullName = serviceSettings["fullName"]
        if (fullName) {
            yourNameField.text = fullName
        }
        _pushCapable = parseInt(serviceSettings["imap4/pushCapable"])

        if (!root.isNewAccount && folderSyncSettings.item) {
            folderSyncSettings.item.setPolicy(accountGeneralSettings["folderSyncPolicy"])
        }
    }

    function _removeGmailEntry(srcModel) {
        for (var i=0; i<srcModel.count; i++) {
            if (srcModel.get(i).serviceName === "google-gmail") {
                srcModel.remove(i)
                break
            }
        }
    }

    function _findService(srcModel, serviceName) {
        for (var i=0; i<srcModel.count; i++) {
            if (srcModel.get(i).serviceName == serviceName) {
                return i
            }
        }
        return -1
    }

    function _orderSyncServices(destModel, srcModel) {
        var orderedServices = ["google-calendars", "google-contacts", "google-gmail"]
        var i=0
        for (i=0; i<orderedServices.length; i++) {
            var serviceIndex = root._findService(srcModel, orderedServices[i])
            if (serviceIndex >= 0) {
                destModel.append(srcModel.get(serviceIndex))
                srcModel.remove(serviceIndex)
            }
        }
        // add remaining unordered services
        for (i=0; i<srcModel.count; i++) {
            destModel.append(srcModel.get(i))
        }
    }

    StandardAccountSettingsLoader {
        id: settingsLoader
        account: root.account
        accountProvider: root.accountProvider
        accountManager: root.accountManager
        autoEnableServices: root.autoEnableAccount

        onSettingsLoaded: {
            root._orderSyncServices(syncServicesRepeater.model, syncServices)
            otherServicesDisplay.serviceModel = otherServices

            // Load the initial settings. Each of these services only have one sync profile.
            var profileId = 0
            var calendarOptions = allSyncOptionsForService("google-calendars")
            for (profileId in calendarOptions) {
                syncContentCombo.currentIndex = calendarOptions[profileId].automaticSyncEnabled ? 0 : 1
                break
            }
            var contactOptions = allSyncOptionsForService("google-contacts")
            for (profileId in contactOptions) {
                root._contactSyncOptionsToLoad = contactOptions[profileId]
                break
            }
            var emailOptions = allSyncOptionsForService("google-gmail")
            for (profileId in emailOptions) {
                emailSchedule.syncOptions = emailOptions[profileId]
                break
            }

            root._emailAvailable = emailSchedule.syncOptions != null
                    && accountSyncManager.templateProfilesAvailable(accountSyncManager.defaultTemplateProfiles(root.accountId, "google-gmail"))
            if (root._emailAvailable) {
                root._populateEmailDetails()
            } else {
                root._removeGmailEntry(syncServicesRepeater.model)
                root._removeGmailEntry(otherServicesDisplay.serviceModel)
            }

            // Sharing via google is not supported at the moment (JB#17350), so don't show
            // google sharing services.
            for (var i=0; i<otherServicesDisplay.serviceModel.count; i++) {
                if (otherServicesDisplay.serviceModel.get(i).serviceName === "picasa") {
                    otherServicesDisplay.serviceModel.remove(i)
                    break
                }
            }
        }
    }

    SectionHeader {
        //: Options for data to be synced with a remote server
        //% "Sync"
        text: qsTrId("settings-accounts-la-sync_options")
    }

    Column {
        id: syncServicesDisplay
        width: parent.width

        Repeater {
            id: syncServicesRepeater

            model: ListModel {}

            Item {
                id: serviceDelegate

                // option is only required for contacts
                property QtObject syncOptions: model.serviceName === "google-contacts"
                                               ? root._contactSyncOptionsToLoad
                                               : null
                readonly property alias switchChecked: serviceSwitch.checked
                readonly property string serviceName: model.serviceName

                width: syncServicesDisplay.width
                height: serviceSwitch.height + (syncOptionCombo.visible ? syncOptionCombo.height : 0)
                visible: serviceSwitch.text.length > 0

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

                        var calendarOrContactServiceEnabled = false
                        for (var i = 0; i < syncServicesRepeater.count; ++i) {
                            var delegateItem = syncServicesRepeater.itemAt(i)
                            if (delegateItem.serviceName === "google-contacts"
                                    || delegateItem.serviceName === "google-calendars") {
                                calendarOrContactServiceEnabled |= delegateItem.switchChecked
                            } else if (delegateItem.serviceName === "google-gmail") {
                                root._gmailServiceEnabled = delegateItem.switchChecked
                            }
                        }
                        root._calendarOrContactServiceEnabled = calendarOrContactServiceEnabled
                    }
                }

                ComboBox {
                    id: syncOptionCombo
                    visible: syncOptions != null
                    anchors.top: serviceSwitch.bottom
                    enabled: serviceSwitch.checked

                    //% "Sync"
                    label: qsTrId("settings-accounts-la-sync")
                    labelMargin: serviceSwitch.leftMargin + Theme.paddingLarge*2    // indent past the TextSwitch glass button

                    menu: ContextMenu {
                        MenuItem {
                            //: Sync data to the device only, do not upload any data
                            //% "To device only"
                            text: qsTrId("settings-accounts-me-to_device_only")
                            onClicked: {
                                serviceDelegate.syncOptions.direction = AccountSyncOptions.OneWayToDevice
                            }
                        }
                        MenuItem {
                            //: Two-way sync. Data will downloaded as well as uploaded.
                            //% "2-ways"
                            text: qsTrId("settings-accounts-me-two_way_sync")
                            onClicked: {
                                serviceDelegate.syncOptions.direction = AccountSyncOptions.TwoWaySync
                            }
                        }
                    }

                    Binding {
                        when: serviceDelegate.syncOptions != null
                        target: syncOptionCombo
                        property: "currentIndex"
                        value: serviceDelegate.syncOptions != null && serviceDelegate.syncOptions.direction == AccountSyncOptions.TwoWaySync ? 1 : 0
                    }
                }
            }
        }
    }

    SectionHeader {
        //: Email details, note this is a section, should mention 'email' here
        //% "Email details"
        text: qsTrId("settings-accounts-la-details_email_google")
    }

    Label {
        x: Theme.horizontalPageMargin
        width: parent.width - x*2
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.highlightColor
        visible: !root._emailAvailable

        //: Indicate that the Email app is required in order to enable email account services
        //% "Email services can be enabled for this account after installing the Email app from the Jolla Store."
        text: qsTrId("settings-accounts-la-email_services_requires_email_app")
    }

    Column {
        id: emailOptions
        width: parent.width
        visible: root._emailAvailable

        TextField {
            id: yourNameField
            inputMethodHints: Qt.ImhNoPredictiveText

            //: Your name
            //% "Your name"
            label: qsTrId("components_accounts-la-genericemail_your_name")
            onTextChanged: root._yourName = text
        }

        TextSwitch {
            id: signatureEnabledSwitch
            checked: true
            //: Include signature in emails
            //% "Include signature"
            text: qsTrId("settings-accounts-la-include_email_signature")
            onCheckedChanged: root._signatureEnabled = checked
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
                return qsTrId("settings_email-la-email_default_signature")
                    .arg(aboutSettings.baseOperatingSystemName)
            }
            onTextChanged: root._signature = text
        }

        SectionHeader {
            //: Options for email sync
            //% "Email sync"
            text: qsTrId("settings-accounts-la-email_sync")
        }

        SyncScheduleOptions {
            id: emailSchedule

            property QtObject syncOptions

            schedule: syncOptions ? syncOptions.schedule : null
            isAlwaysOn: syncOptions ? syncOptions.syncExternallyEnabled : false
            showAlwaysOn: root._pushCapable
            intervalModel: EmailIntervalListModel {}
            enabled: root._gmailServiceEnabled

            onAlwaysOnChanged: {
                syncOptions.syncExternallyEnabled = state
            }
        }

        Loader {
            width: parent.width
            height: item ? item.height : 0
            sourceComponent: (emailSchedule.syncOptions
                              && emailSchedule.syncOptions.schedule.enabled
                              && emailSchedule.syncOptions.schedule.peakScheduleEnabled) ? emailPeakOptions : null
            Component {
                id: emailPeakOptions
                PeakSyncOptions {
                    schedule: emailSchedule.syncOptions.schedule
                    showAlwaysOn: root._pushCapable
                    intervalModel: EmailIntervalListModel {}
                    offPeakIntervalModel: EmailOffPeakIntervalListModel {}
                }
            }
        }

        Loader {
            // FolderSyncSettings availability depends on email packages being installed
            id: folderSyncSettings
            width: parent.width
            active: root._emailAvailable
            source: "FolderSyncSettings.qml"
            onLoaded: {
                item.accountId = Qt.binding(function() { return root.accountId })
                item.active = Qt.binding(function() { return !root.isNewAccount })
                item.enabled = Qt.binding(function() { return root._gmailServiceEnabled })
            }
        }
    }

    SectionHeader {
        //: Options for data sync
        //% "Content sync"
        text: qsTrId("settings-accounts-la-content_sync")
    }

    // For google contacts and calendars, we do not allow customization of the sync schedule.
    // We either sync it automatically as per the internal schedule, or not at all. Contacts
    // and Images in particular are expensive to update and don't need to be synced often.
    ComboBox {
        id: syncContentCombo
        //% "Sync content"
        label: qsTrId("settings-accounts-la-sync_content")
        enabled: root._calendarOrContactServiceEnabled

        menu: ContextMenu {
            MenuItem {
                //: Sync data automatically as necessary
                //% "Automatically"
                text: qsTrId("settings-accounts-la-sync_automatically")
                onClicked: {
                    root._enableAutoSync("google-calendars", true)
                    root._enableAutoSync("google-contacts", true)
                }
            }
            MenuItem {
                //: Only sync when user manually requests it; do not sync automatically
                //% "Manually"
                text: qsTrId("settings-accounts-la-sync_manually")
                onClicked: {
                    root._enableAutoSync("google-calendars", false)
                    root._enableAutoSync("google-contacts", false)
                }
            }
        }
    }

    AccountServiceSettingsDisplay {
        id: otherServicesDisplay
        enabled: root.accountEnabled
        visible: !!serviceModel && serviceModel.count > 0

        onUpdateServiceEnabledStatus: {
            if (enabled) {
                root.account.enableWithService(serviceName)
            } else {
                root.account.disableWithService(serviceName)
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
