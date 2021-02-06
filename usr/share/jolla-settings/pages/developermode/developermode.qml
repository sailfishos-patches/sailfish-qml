/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.DBus 2.0
import com.jolla.settings.system 1.0
import com.jolla.settings.accounts 1.0
import org.nemomobile.configuration 1.0
import org.nemomobile.devicelock 1.0
import org.nemomobile.systemsettings 1.0
import org.nemomobile.notifications 1.0
import Sailfish.Policy 1.0
import Sailfish.Accounts 1.0
import Nemo.Ssu 1.1
import MeeGo.Connman 0.2

Page {
    id: root

    property bool initialized
    property bool disablingSsuRemorse
    property bool disablingRemoteLoginRemorse

    property bool showDeveloperModeSettings: developerModeSettings.developerModeEnabled && !devAccountPrompt.active
    readonly property bool hasDeveloperAccount: accountManager.hasAccountForProvider(accountManager.accountIdentifiers, developerAccountProvider)
    property string developerAccountProvider

//    DummyDeveloperModeSettings {  // Replace for mock backend to test UI
    DeveloperModeSettings {
        id: developerModeSettings
    }

    AccountManager {
        id: accountManager

        function developerAccountProvider() {
            var names = providerNames
            for (var i = 0; i < names.length; ++i) {
                var accountProvider = provider(names[i])
                if (providerHasService(accountProvider, "developermode")) {
                    return names[i]
                }
            }
            return ""
        }

        function providerHasService(provider, serviceName) {
            var serviceNames = provider.serviceNames
            for (var i = 0; i < serviceNames.length; ++i) {
                var accountService = service(serviceNames[i])
                if (accountService.serviceType == serviceName) {
                    return true
                }
            }
            return false
        }

        function hasAccountForProvider(accountIds, providerName) {
            for (var i = 0; i < accountIds.length; ++i) {
                if (account(accountIds[i]).providerName == providerName) {
                    return true
                }
            }
            return false
        }

        Component.onCompleted: root.developerAccountProvider = developerAccountProvider()
        onProviderNamesChanged: root.developerAccountProvider = developerAccountProvider()
    }

    NetworkManager {
        id: networkManager
        readonly property bool online: state == "online"
    }

    DBusInterface {
        id: connectionSelector

        service: "com.jolla.lipstick.ConnectionSelector"
        path: "/"
        iface: "com.jolla.lipstick.ConnectionSelectorIf"
        signalsEnabled: true
        property var onlineCallback

        function online(callback) {
            if (networkManager.online) {
                callback()
            } else {
                onlineCallback = callback
                open()
            }
        }

        function open() {
            call('openConnectionNow', '') // wifi + mobile
        }

        function connectionSelectorClosed(connectionSelected) {
            if (networkManager.online && onlineCallback !== undefined) {
                onlineCallback()
                onlineCallback = undefined
            }
        }
    }

    function online(callback) {
        connectionSelector.online(callback)
    }

    function showDisclaimerDialog() {
        var obj = pageStack.currentPage == root ?
            pageStack.animatorPush('DisclaimerDialog.qml') :
            pageStack.animatorReplaceAbove(root, 'DisclaimerDialog.qml')
        obj.pageCompleted.connect(function(dialog) {
            dialog.accepted.connect(function() {
                developerModeSettings.setDeveloperMode(true)
            })
        })
    }

    // Replace with AccountFactory mock backend to test UI
    // QtObject { id: accountFactory;  function jollaAccountExists() { return true } }

    Notification {
        id: notification

        isTransient: true
        appIcon: "icon-system-resources"
        urgency: Notification.Critical
    }

    function refreshSettings() {
        // Refresh IP addresses
        developerModeSettings.refresh()

        // Need to set the text here from the config, as property bindings
        // do not work for text fields as soon as they are edited
        usbIpAddress.text = developerModeSettings.usbIpAddress
    }

    onStatusChanged: {
        if (status == PageStatus.Active) {
            if (initialized) {
                refreshSettings()
            }
            initialized = true
        } else if (status === PageStatus.Deactivating) {
            deviceLockQuery.cachedAuth = false
        }
    }

    Timer {
        id: repoRefreshTimer
        interval: 20000
        onRunningChanged: {
            if (running) {
                repoRefresher.refreshRepos()
                //% "Refreshing"
                refreshStatusText.text = qsTrId("settings_developermode-la-refresh_started")
            }
        }
        onTriggered: {
            //% "Timeout"
            refreshStatusText.text = qsTrId("settings_developermode-la-timeout_on_refresh")
        }
    }

    RepositoryRefresh {
        id: repoRefresher
    }

    Connections {
        target: Qt.application
        onActiveChanged: {
            if (Qt.application.active) {
                refreshSettings()
            }
        }
    }

    function authenticate(onAuthenticated, returnOnAccept) {
        if (!deviceLockQuery.cachedAuth) {
            if (returnOnAccept === false) {
                deviceLockQuery.returnOnAccept = false
            }
            deviceLockQuery.authenticate(deviceLockSettings.authorization, function(token) {
                deviceLockQuery.cachedAuth = true
                onAuthenticated()
                deviceLockQuery.returnOnAccept = true
            }, function() {
                deviceLockQuery.returnOnAccept = true
            })
        } else {
            onAuthenticated()
        }
    }

    function setStored() {
        passwordField.storedByManager = true
        passwordField.changingPassword = false
    }

    function savePassword() {
        // do not set passwordField.changingPassword = true
        // we are about to save  user edited which will not be visible
        // in the UI.

        authenticate(function() {
            passwordField.storedByManager = false
            passwordManager.call('setPassword', [passwordField.text], setStored, setStored)
            passwordField.focus = false
        })
    }

    function clearPassword() {
        passwordField.changingPassword = true

        authenticate(function() {
            passwordField.storedByManager = false
            passwordField.text = ''
            passwordField.requireAuthentication = false
            passwordManager.call('setPassword', [''], setStored, setStored)
            passwordField.focus = false
        })
    }

    DeviceLockSettings {
        id: deviceLockSettings
    }

    DBusInterface {
        id: passwordManager
        bus: DBus.SystemBus
        service: 'org.nemo.passwordmanager'
        path: '/org/nemo/passwordmanager'
        iface: 'org.nemo.passwordmanager'
        signalsEnabled: true

        // Password login enabled == password is set (user selected or generated)
        property bool passwordLoginEnabled
        // Whether password is generated or something else (set by user or unset, see above)
        property bool passwordIsGenerated

        function passwordChanged() {
            typedCall('getGeneratedPassword', [], function (password) {
                passwordIsGenerated = password != ''
                passwordField.text = password
                passwordField.storedByManager = true
                passwordField.changingPassword = false
            })
        }

        function loginEnabledChanged(enabled) {
            if (passwordLoginEnabled != enabled) {
                passwordLoginEnabled = enabled
            }
        }

        function remoteLoginEnabledChanged(enabled) {
            if (remoteLoginSwitch.checked != enabled) {
                remoteLoginSwitch.checked = enabled
            }
        }

        function error(message) {
            console.log('Password Manager Error: ' + message)
        }
    }

    QtObject {
        id: ssu

        property bool registered
        property string currentDomain
        property bool rndMode

        function register(username, password, domain) {
            if (domain) {
                var n = username.search("@")
                if (n >= 0)
                    username = username.substr(0, n)
                username = username + "@" + domain
            }
            ssuDBus.call('registerDevice', [username, password])
        }

        function unregister() {
            ssuDBus.typedCall('unregisterDevice', [])
        }

        function retrieveRegistrationStatus() {
            ssuDBus.typedCall('isRegistered', [], function (registered) {
                ssu.registered = registered
            })
            ssuDBus.typedCall('domain', [], function (domain) {
                ssu.currentDomain = domain
            })
            ssuDBus.typedCall('deviceMode', [], function (deviceMode) {
                ssu.rndMode = !!(deviceMode & Ssu.RndMode)
            })
        }
    }

    DBusInterface {
        id: ssuDBus
        bus: DBus.SystemBus
        service: 'org.nemo.ssu'
        path: '/org/nemo/ssu'
        iface: 'org.nemo.ssu'
        signalsEnabled: true

        function done() {
            ssuDBus.typedCall('error', [], function (errorStatus) {
                if (errorStatus) {
                    ssuDBus.typedCall('lastError', [], function (message) {
                        console.log('SSU Error: ' + message)
                        notification.body = message
                        notification.publish()
                    })
                }
            })
        }

        function registrationStatusChanged() {
            ssu.retrieveRegistrationStatus()
        }
    }

    DBusInterface {
        id: abootSettingsDBus
        property int isLocked
        property bool fetching
        property bool hasAbootSettingsService

        bus: DBus.SystemBus
        service: 'org.sailfishos.abootsettings'
        path: '/org/sailfishos/abootsettings'

        Component.onCompleted: checkAbootSettingsService()

        // Check first that we have aboot settings service available.
        function checkAbootSettingsService() {
            fetching = true
            iface = 'org.freedesktop.DBus.Peer'
            call('Ping', [], function () {
                hasAbootSettingsService = true
                getLocked()
            }, function() {
                hasAbootSettingsService = false
            })
        }

        function getLocked() {
            fetching = true
            iface = 'org.sailfishos.abootsettings'
            call('get_locked', [], function (retval) {
                isLocked = retval
                fetching = false
            }, function () {
                fetching = false
            })
        }

        function setLocked(newLockedValue) {
            fetching = true
            iface = 'org.sailfishos.abootsettings'
            call('set_locked', [newLockedValue], function (retval) {
                fetching = false
                if (!retval) {
                     console.log("[developermode] Failed to set locked")
                } else {
                    isLocked = newLockedValue
                }
            }, function () {
                fetching = false
                console.log("[developermode] Failed to set locked")
            })
        }
    }

    PolicyValue {
        id: policy
        policyType: PolicyValue.DeveloperModeSettingsEnabled
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        opacity: 1 - developerModeWorkProgressBar.opacity
        enabled: !developerModeWorkProgressBar.enabled

        Column {
            id: column
            width: parent.width
            bottomPadding: Theme.paddingLarge

            PageHeader {
                //% "Developer tools"
                title: qsTrId("settings_developermode-he-developer_tools")
            }

            DisabledByMdmBanner {
                id: diagnosticModeBanner
                active: !policy.value
            }

            Loader {
                id: devAccountPrompt

                function reload() {
                    if (active) {
                        var props = {
                            "accountProviderName": Qt.binding(function() {
                                return root.developerAccountProvider
                            })
                        }
                        setSource(Qt.resolvedUrl("DeveloperAccountPrompt.qml"), props)
                    }
                }

                Component.onCompleted: reload()
                onActiveChanged: reload()

                width: parent.width
                height: item ? item.height : 0

                active: !root.hasDeveloperAccount
                        && !developerModeSettings.developerModeEnabled
                        && developerModeSettings.repositoryAccessRequired
                        && policy.value
            }

            TextSwitch {
                visible: !devAccountPrompt.active
                automaticCheck: false
                checked: developerModeSettings.developerModeEnabled
                enabled: policy.value

                //% "Developer mode"
                text: qsTrId("settings_developermode-bu-enable_developer_mode")

                onClicked: {
                    if (developerModeSettings.developerModeEnabled) {
                        if (deviceLockQuery._availableMethods != Authenticator.NoAuthentication) {
                            root.authenticate(function() {
                                developerModeSettings.setDeveloperMode(false)
                                passwordManager.call('setRemoteLoginEnabled', [false])
                            })
                        } else {
                            //% "Disabling developer mode"
                            Remorse.popupAction(root, qsTrId("settings_developermode-la-disabling_developer_mode"), function() {
                                developerModeSettings.setDeveloperMode(false)
                                passwordManager.call('setRemoteLoginEnabled', [false])
                            })
                        }
                    } else {
                        if (!ssu.registered && developerModeSettings.repositoryAccessRequired) {
                            if (ssu.rndMode) {
                                //% "Device in R&D mode, enable developer updates below"
                                notification.body = qsTrId("settings_developermode-la-rnd_enable_developer_updates")
                                notification.publish()
                                return
                            } else if (ssu.currentDomain === "cbeta") {
                                //% "Device in CBeta domain, enable developer updates below"
                                notification.body = qsTrId("settings_developermode-la-cbeta_enable_developer_updates")
                                notification.publish()
                                return
                            } else if (ssu.currentDomain !== "sales") {
                                //% "Device in '%0' domain, enable developer updates below"
                                notification.body = qsTrId("settings_developermode-la-custom_domain_enable_developer_updates").arg(ssu.currentDomain)
                                notification.publish()
                                return
                            }
                        }

                        if (developerModeSettings.repositoryAccessRequired) {
                            online(function() { root.authenticate(showDisclaimerDialog, false) })
                        } else {
                            root.authenticate(showDisclaimerDialog, false)
                        }
                    }
                }
            }

            Column {
                width: parent.width
                visible: root.showDeveloperModeSettings

                TextSwitch {
                    id: remoteLoginSwitch

                    enabled: policy.value && !disablingRemoteLoginRemorse
                    automaticCheck: false
                    onClicked: {
                        if (checked) {
                            checked = false
                            //% "Remote connection disabled"
                            var remorse = Remorse.popupAction(root, qsTrId("settings_developermode-la-disabled_remote_connection"), function() {
                                passwordManager.call('setRemoteLoginEnabled', [false])
                            })
                            remorse.canceled.connect(function() { remoteLoginSwitch.checked = true })
                            disablingRemoteLoginRemorse = Qt.binding(function () { return remorse && remorse.active })
                        } else {
                            authenticate(function() {
                                passwordManager.call('setRemoteLoginEnabled', [true])
                            })
                        }
                    }

                    //% "Remote connection"
                    text: qsTrId("settings_developermode-bu-enable_remote_connection")

                    //% "Allow login via SSH with username '%0'"
                    description: qsTrId("settings_developermode-la-allow_login_via_ssh_username").arg(developerModeSettings.username)
                }

                Column {
                    width: parent.width
                    height: enabled ? implicitHeight : 0.0
                    enabled: policy.value
                    opacity: enabled ? 1.0 : 0.0

                    Behavior on opacity {
                        enabled: initialized
                        FadeAnimation { }
                    }
                    Behavior on height {
                        enabled: initialized
                        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                    }

                    SystemPasswordField {
                        id: passwordField

                        // True when password change is being processed
                        property bool changingPassword

                        // Is current value saved by passwordManager
                        property bool storedByManager
                        // Use dotted password as placeholder instead of help text
                        readonly property bool usePlaceholderPassword: passwordManager.passwordLoginEnabled && !activeFocus

                        // Note: according to qt documention, enabled value should inherit, but currently it doesn't
                        // change property value, thus duplicating it
                        enabled: policy.value

                        placeholderAnimationEnabled: false
                        placeholderText: (!usePlaceholderPassword || changingPassword
                            //% "Set password"
                            ? qsTrId("settings_developermode-ph-enter_password")
                            : "\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022")

                        showEchoModeToggle: (!usePlaceholderPassword || text != '') && activeFocus || (passwordManager.passwordIsGenerated && storedByManager)

                        //% "Password"
                        label: qsTrId("settings_developermode-la-password")
                        hideLabelOnEmptyField: !usePlaceholderPassword

                        onTextChanged: if (focus) storedByManager = false

                        EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                        EnterKey.onClicked: {
                            root.savePassword()
                            focus = false
                        }

                        width: parent.width
                    }

                    ButtonLayout {
                        Button {
                            id: generateButton

                            enabled: policy.value
                            //% "Generate"
                            text: qsTrId("settings_developermode-bu-generate_password")
                            onClicked: {
                                passwordField.changingPassword = true
                                root.authenticate(function() {
                                    passwordManager.typedCall('generatePassword', [], function() {
                                        // Show the password once it has been generated
                                        passwordField._usePasswordEchoMode = false
                                    }, function() {
                                        passwordField.changingPassword = false
                                    })
                                })
                            }
                        }

                        Button {
                            id: saveButton

                            readonly property bool clear: passwordField.storedByManager && passwordManager.passwordLoginEnabled || !passwordField.storedByManager && passwordField.text == ''

                            enabled: policy.value && (!passwordField.storedByManager || clear)
                            text: (!clear
                                //% "Save"
                                ? qsTrId("settings_developermode-bu-set_password")
                                //% "Clear"
                                : qsTrId("settings_developermode-bu-clear_password"))

                            onClicked: !clear ? root.savePassword() : root.clearPassword()
                        }
                    }
                }

                SectionHeader {
                    //% "Networking"
                    text: qsTrId("settings_developermode-la-network")
                }

                NetworkAddressField {
                    icon: 'image://theme/icon-m-wlan'
                    //% "WLAN IP address"
                    caption: qsTrId("settings_developermode-la-wlan_ip_address")
                    text: developerModeSettings.wlanIpAddress
                    readOnly: true

                    onClicked: pageStack.animatorPush(Qt.resolvedUrl('../wlan/mainpage.qml'))

                    visible: root.showDeveloperModeSettings
                }

                NetworkAddressField {
                    id: usbIpAddress

                    icon: 'image://theme/icon-m-usb'
                    //% "USB IP address"
                    caption: qsTrId("settings_developermode-la-usb_ip_address")
                    text: developerModeSettings.usbIpAddress
                    onSubmit: {
                        if (acceptableInput) {
                            developerModeSettings.setUsbIpAddress(text)
                        }
                    }
                    submitOnDefocus: true

                    //% "IP address"
                    placeholderText: qsTrId("settings_developermode-ph-ip_address")

                    validator: RegExpValidator {
                        // Only do some very basic syntax checking, not a full
                        // validation of IP addresses (this is developer mode)
                        regExp: /^\d+\.\d+\.\d+\.\d+$/
                    }
                }
            }

            Column {
                width: parent.width

                SectionHeader {
                    //% "SSU"
                    text: qsTrId("settings_developermode-la-ssu")
                }

                TextSwitch {
                    enabled: !disablingSsuRemorse
                    automaticCheck: false
                    checked: ssu.registered && enabled

                    onClicked: {
                        if (ssu.registered) {
                            //% "Developer updates disabled"
                            var remorse = Remorse.popupAction(root, qsTrId("settings_developermode-la-disabled_developer_updates"), function() {
                                ssu.unregister()
                            })
                            disablingSsuRemorse = Qt.binding(function () { return remorse && remorse.active })

                        } else {
                            online(function() {
                                var obj = pageStack.animatorPush('RegisterSSUDialog.qml')
                                obj.pageCompleted.connect(function(dialog) {
                                    dialog.accepted.connect(function() {
                                        ssu.register(dialog.username, dialog.password, dialog.domain)
                                    })
                                })
                            })
                        }
                    }

                    //% "Enable developer updates"
                    text: qsTrId("settings_developermode-bu-enable_developer_updates")

                    //% "Successfully registered with SSU in '%0' domain"
                    description: ssu.registered ? qsTrId("settings_developermode-la-ssu_enabled").arg(ssu.currentDomain)
                                                  //% "Access to developer repositories requires registration"
                                                : qsTrId("settings_developermode-la-ssu_registration")
                }
            }

            Column {
                width: parent.width

                SectionHeader {
                    //% "Tools"
                    text: qsTrId("settings_developermode-he-tools")
                }

                ComboBox {
                    id: frameRateCombo

                    readonly property var values: [
                        "",
                        "simple",
                        "detailed",
                        "simple-compositor",
                        "detailed-compositor",
                        "simple-application",
                        "detailed-application"
                    ]

                    //% "Framerate display"
                    label: qsTrId("settings_developermode-cb-framerate_display")
                    menu: ContextMenu {
                        MenuItem {
                            //% "Off"
                            text: qsTrId("settings_developermode-va-off")
                        }
                        MenuItem {
                            //% "Simple"
                            text: qsTrId("settings_developermode-va-simple")
                        }
                        MenuItem {
                            //% "Detailed"
                            text: qsTrId("settings_developermode-va-detailed")
                        }
                        MenuItem {
                            //% "Simple - Compositor only"
                            text: qsTrId("settings_developermode-va-simple_compositor")
                        }
                        MenuItem {
                            //% "Detailed - Compositor only"
                            text: qsTrId("settings_developermode-va-detailed_compositor")
                        }
                        MenuItem {
                            //% "Simple - Application only"
                            text: qsTrId("settings_developermode-va-simple_application")
                        }
                        MenuItem {
                            //% "Detailed - Application only"
                            text: qsTrId("settings_developermode-va-detailed_capplication")
                        }
                    }

                    onCurrentIndexChanged: frameRateConfig.value = values[currentIndex] || ""

                    ConfigurationValue {
                        id: frameRateConfig

                        key: "/desktop/jolla/silica_framerate"
                        onValueChanged: syncValue()
                        Component.onCompleted: syncValue()

                        function syncValue() {
                            frameRateCombo.currentIndex = Math.max(0, frameRateCombo.values.indexOf(value))
                        }
                    }
                }

                TextSwitch {
                    //% "Show reboot action on top menu"
                    text: qsTrId("settings_developermode-bu-show_reboot_action")

                    automaticCheck: false
                    checked: rebootActionConfig.value
                    onClicked: rebootActionConfig.value = !rebootActionConfig.value

                    ConfigurationValue {
                        id: rebootActionConfig

                        key: "/desktop/jolla/reboot_action_enabled"
                        defaultValue: false
                    }
                }

                TextSwitch {
                    //% "Allow USB diagnostic mode"
                    text: qsTrId("settings_developermode-bu-allow_usb_diagnostic_mode")

                    automaticCheck: false
                    checked: usbSettings.hiddenModes.indexOf("diag_mode") === -1
                    visible: usbSettings.hiddenModes.indexOf("diag_mode") >= 0
                             || usbSettings.supportedModes.indexOf("diag_mode") >= 0
                    enabled: !diagnosticModeBanner.active

                    description: !diagnosticPolicy.value
                            //: %1 is operating system name without OS suffix
                            //% "Disabled by %1 Device Manager"
                            ? qsTrId("settings_system-la-disabled_by_device_manager")
                                .arg(aboutSettings.baseOperatingSystemName)
                            : ""

                    onClicked: {
                        if (checked) {
                            usbSettings.hideMode("diag_mode")
                        } else {
                            usbSettings.unhideMode("diag_mode")
                        }
                    }

                    USBSettings { id: usbSettings }

                    PolicyValue {
                        id: diagnosticPolicy
                        policyType: PolicyValue.UsbDiagnosticModeEnabled
                    }
                }

                TextSwitch {
                    automaticCheck: false
                    // Invert since flash is allowed when unlocked.
                    checked: !abootSettingsDBus.isLocked
                    // Don't show switch if service is not available or
                    // developer mode is not enabled.
                    visible: abootSettingsDBus.hasAbootSettingsService && root.showDeveloperModeSettings
                    busy: abootSettingsDBus.fetching

                    //: User can unlock the bootloader and flash device with a flash tool.
                    //% "Allow bootloader operations"
                    text: qsTrId("settings_developermode-bt-allow_bootloader_operations")

                    onClicked: {
                        if (abootSettingsDBus.isLocked) {
                            abootSettingsDBus.setLocked(0)
                        } else {
                            abootSettingsDBus.setLocked(1)
                        }
                    }
                }

                TextSwitch {
                    visible: root.showDeveloperModeSettings
                    automaticCheck: false
                    checked: developerModeSettings.debugHomeEnabled
                    enabled: policy.value

                    //: Content effectively under /home/.system/usr/lib/debug
                    //% "Store debug symbols to home partition"
                    text: qsTrId("settings_developermode-bu-enable_debug_home_location")

                    onClicked: {
                        if (developerModeSettings.debugHomeEnabled) {
                            developerModeSettings.moveDebugToHome(false)
                        } else {
                            developerModeSettings.moveDebugToHome(true)
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: Theme.paddingLarge
                }
            }

            Column {
                width: parent.width
                visible: repoRefresher.enabled
                spacing: Theme.paddingMedium

                Connections {
                    target: repoRefresher
                    onReposRefreshed: {
                        //% "Repositories refreshed"
                        refreshStatusText.text = qsTrId("settings_developermode-la-repositories_refreshed")
                        repoRefreshTimer.running = false
                    }
                    onRefreshFailed: {
                        //% "Repository refresh failed"
                        refreshStatusText.text = qsTrId("settings_developermode-la-refresh_failed")
                        repoRefreshTimer.running = false
                    }
                }

                SectionHeader {
                    //% "Repositories"
                    text: qsTrId("settings_developermode-la-repos")
                }

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x
                    wrapMode: Text.Wrap
                    color: Theme.highlightColor
                    //% "Refresh package repositories"
                    text: qsTrId("settings_developermode-la-refresh_repos")
                }

                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    //% "Refresh"
                    text: qsTrId("settings_developermode-bu-refresh_repos")
                    onClicked: {
                        repoRefreshTimer.running = true
                    }
                }

                Label {
                    id: refreshStatusText
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x
                    wrapMode: Text.Wrap
                    color: Theme.highlightColor
                }
            }
        }
        VerticalScrollDecorator {}
    }

    ProgressBar {
        id: developerModeWorkProgressBar

        width: parent.width
        anchors.verticalCenter: parent.verticalCenter
        value: developerModeSettings.workProgress
        minimumValue: 0
        maximumValue: 100
        indeterminate: developerModeSettings.workStatus == DeveloperModeSettings.Preparing
        label: {
            switch (developerModeSettings.workStatus) {
            case DeveloperModeSettings.Preparing:
                //% "Preparing changes"
                return qsTrId("settings_developermode-la-preparing_changes")
            case DeveloperModeSettings.DownloadingPackages:
                //% "Downloading packages"
                return qsTrId("settings_developermode-la-downloading_packages")
            case DeveloperModeSettings.InstallingPackages:
                if (developerModeSettings.installationType == DeveloperModeSettings.DebugHome) {
                    //% "Installing debug home location"
                    return qsTrId("settings_developermode-la-installing_debug_home_location")
                } else if (developerModeSettings.installationType == DeveloperModeSettings.DeveloperMode){
                    //% "Installing developer mode"
                    return qsTrId("settings_developermode-la-installing_developer_mode")
                } else {
                    return ""
                }

            case DeveloperModeSettings.RemovingPackages:
                if (developerModeSettings.installationType == DeveloperModeSettings.DebugHome) {
                    //% "Removing debug home location"
                    return qsTrId("settings_developermode-la-removing_debug_home_location")
                } else if (developerModeSettings.installationType == DeveloperModeSettings.DeveloperMode) {
                    //% "Removing developer mode"
                    return qsTrId("settings_developermode-la-removing_developer_mode")
                } else {
                    return ""
                }

            case DeveloperModeSettings.Idle:
            default:
                return ""
            }
        }

        enabled: developerModeSettings.workStatus != DeveloperModeSettings.Idle
        opacity: enabled ? 1.0 : 0.0
        Behavior on opacity { FadeAnimation {} }
    }

    Component.onCompleted: {
        /* Request existing password from the password manager */
        passwordManager.passwordChanged()
        passwordManager.call('isLoginEnabled', [], passwordManager.loginEnabledChanged)

        /* Check if remote connection (SSH) has been enabled */
        passwordManager.call('isRemoteLoginEnabled', [], passwordManager.remoteLoginEnabledChanged)

        /* Request registration status from SSU */
        ssu.retrieveRegistrationStatus()
    }

    Component.onDestruction: {
        /* Tell password manager to quit (it will be respawned on demand) */
        passwordManager.call('quit', [])
    }

    DeviceLockQuery {
        id: deviceLockQuery

        property bool cachedAuth
        property bool active: Qt.application.active
        onActiveChanged: if (!active) cachedAuth = false
        returnOnAccept: true
        returnOnCancel: true
    }

    AboutSettings {
        id: aboutSettings
    }
}
