import QtQuick 2.0
import Sailfish.Silica 1.0
// Load translations
import com.jolla.settings 1.0
import Nemo.DBus 2.0
import Nemo.Notifications 1.0
import "./pages"

ApplicationWindow {
    id: window

    property Page _mainPage

    allowedOrientations: Screen.sizeCategory > Screen.Medium
                         ? defaultAllowedOrientations
                         : defaultAllowedOrientations & Orientation.PortraitMask
    _defaultPageOrientations: Orientation.All
    _defaultLabelFormat: Text.PlainText

    initialPage: Component { MainPage { id: mainPage; Component.onCompleted: window._mainPage = mainPage} }

    cover: Qt.resolvedUrl("pages/SettingsCover.qml")

    // Function to show a setting page specified by the url. This cleans the stack
    // to the first page before pushing the new pages on a stack. Otherwise the stack
    // might have the same page twice.
    function showSettingsPage(section, url, properties) {
        if (!pageStack.currentPage.backNavigation) {
            showBusyWarning()
            return
        }

        pageStack.pop(_mainPage, PageStackAction.Immediate)
        _mainPage.moveToSection(section)
        pageStack.push(url, properties || {}, PageStackAction.Immediate)
        window.activate()
    }

    function showSettingsSection(section) {
        if (!pageStack.currentPage.backNavigation) {
            showBusyWarning()
            return
        }

        pageStack.pop(_mainPage, PageStackAction.Immediate)
        _mainPage.moveToSection(section)
        window.activate()
    }

    function showBusyWarning() {
        //: system notification shown when settings is requested to show a page but it's busy
        //% "Settings application is busy"
        notification.previewBody = qsTrId("settings-he-warning_settings_busy")
        notification.publish()
    }

    Notification {
        id: notification

        isTransient: true
    }

    // Add new signals and signal handlers below if there's a need to support opening
    // other pages too.
    DBusAdaptor {
        service: "com.jolla.settings"
        path: "/com/jolla/settings/ui"
        iface: "com.jolla.settings.ui"

        function showSettings() {
            window.showSettingsSection("system_settings")
        }

        function showTransfers() {
            window.showSettingsPage("system_settings", Qt.resolvedUrl("pages/transferui/mainpage.qml"))
        }

        function showAccounts() {
            window.showSettingsSection("accounts")
        }

        function showSailfishOs() {
            window.showSettingsPage("system_settings", Qt.resolvedUrl("pages/sailfishos/mainpage.qml"))
        }

        function showLocationSettings() {
            window.showSettingsPage("system_settings", Qt.resolvedUrl("pages/gps_and_location/location.qml"))
        }

        function showEventsSettings() {
            window.showSettingsPage("system_settings", Qt.resolvedUrl("pages/events/events.qml"))
        }

        function showCallRecordings() {
            window.showSettingsPage("applications", Qt.resolvedUrl("pages/jolla-voicecall/voicecall.qml"), { "showRecordingsImmediately": true })
        }

        function showAddNetworkDialog() {
            window.showSettingsPage("system_settings", Qt.resolvedUrl("pages/wlan/mainpage.qml"), { "showAddNetworkDialog": true })
        }

        function importVpn(args) {
            window.showSettingsPage("system_settings", Qt.resolvedUrl("pages/vpn/mainpage.qml"), { "importPath": args[1], "importMime": args[0] })
        }

        function findBluetoothDevices() {
            window.showSettingsPage("system_settings", Qt.resolvedUrl("pages/bluetooth/bluetoothSettings.qml"))
            pageStack.currentPage.autoStartDiscovery()
        }

        function newVpnConnection() {
            window.showSettingsPage("system_settings", Qt.resolvedUrl("pages/vpn/mainpage.qml"))
            pageStack.push(Qt.resolvedUrl("pages/vpn/NewConnectionDialog.qml"), {}, PageStackAction.Immediate)
        }

        function showAmbienceSettings(ambienceContentId) {
            window.showSettingsPage("system_settings", Qt.resolvedUrl("pages/jolla-gallery-ambience/ambience.qml"), {})
            pageStack.push("com.jolla.gallery.ambience.AmbienceSettingsPage", { "contentId": ambienceContentId }, PageStackAction.Immediate)
        }

        function importWebcal(path) {
            var comp = Qt.createComponent("/usr/share/accounts/ui/webcal.qml")
            if (comp.status !== Component.Ready) {
                console.warn("Cannot load webcal.qml: " + comp.errorString())
                return
            }
            var agent = comp.createObject(window, {'remoteUrl': path})
            if (agent === null) {
                console.warn("Unable to instantiate webcal.qml")
                return
            }
            showAccounts()
            if (pageStack.currentPage.backNavigation) {
                // We're not busy and can show the account page.
                agent.endDestination = pageStack.currentPage
                agent.endDestinationAction = PageStackAction.Pop
                pageStack.push(agent.initialPage, {}, PageStackAction.Immediate)
            }
        }

        function addNewUser() {
            window.showSettingsPage("system_settings", Qt.resolvedUrl("pages/users/users.qml"), { "enableUserCreationOnceComplete": true })
        }

        function showPage(path) {
            path = path.toString()
            var obj = _mainPage.objectForPath(path)
            if (obj) {
                if (obj.type === "page") {
                    var params = obj.data()["params"]

                    if (params["source"]) {
                        window.showSettingsPage(path, params["source"])
                    } else {
                        console.warn("Settings app requested to show settings page, but no page source defined for the config '" + path + "'")
                    }
                } else {
                    console.warn("Settings app requested to show a settings page, but the config '" + path + "' is of wrong type '" + obj.type + "'")
                }
            } else {
                console.warn("Settings app requested to show settings page, but no config found for path", path)
            }
        }

        function activateWindow(arg) {
            window.activate()
        }
    }

    DBusAdaptor {
        path: "/share_signing_keys"
        iface: "org.sailfishos.share"

        function share(shareActionConfiguration) {
            window.showSettingsPage("system_settings", Qt.resolvedUrl("pages/keys/SigningSharePage.qml"),
                                    { "shareActionConfiguration": shareActionConfiguration })
        }
    }
}
