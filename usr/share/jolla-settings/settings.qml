import QtQuick 2.0
import Sailfish.Silica 1.0
// Load translations
import com.jolla.settings 1.0
import org.nemomobile.dbus 2.0
import org.nemomobile.notifications 1.0
import "./pages"

ApplicationWindow {
    id: window

    property Page _frontPage

    allowedOrientations: Screen.sizeCategory > Screen.Medium
                         ? defaultAllowedOrientations
                         : defaultAllowedOrientations & Orientation.PortraitMask
    _defaultPageOrientations: Orientation.All
    _defaultLabelFormat: Text.PlainText

    initialPage: Component { FrontPage { id: frontPage; Component.onCompleted: window._frontPage = frontPage} }

    cover: Qt.resolvedUrl("pages/SettingsCover.qml")

    // Function to show a setting page specified by the url. This cleans the stack
    // to the first page before pushing the new pages on a stack. Otherwise the stack
    // might have the same page twice.
    function showSettingsPage(url, properties) {
        if (!pageStack.currentPage.backNavigation) {
            showBusyWarning()
            return
        }

        pageStack.pop(_frontPage, PageStackAction.Immediate)
        pageStack.push(url, properties || {}, PageStackAction.Immediate)
        window.activate()
    }

    function showSettingsSection(section) {
        if (!pageStack.currentPage.backNavigation) {
            showBusyWarning()
            return
        }

        pageStack.pop(_frontPage, PageStackAction.Immediate)
        _frontPage.moveToSection(section)
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
            // Jumps to initial page
            if (!pageStack.currentPage.backNavigation) {
                window.showBusyWarning()
                return
            }

            pageStack.pop(_frontPage, PageStackAction.Immediate)
            window.activate()
        }

        function showTransfers() {
            window.showSettingsPage(Qt.resolvedUrl("pages/transferui/mainpage.qml"))
        }

        function showAccounts() {
            window.showSettingsPage(Qt.resolvedUrl("pages/accounts/mainpage.qml"))
        }

        function showSailfishOs() {
            window.showSettingsPage(Qt.resolvedUrl("pages/sailfishos/mainpage.qml"))
        }

        function showLocationSettings() {
            window.showSettingsPage(Qt.resolvedUrl("pages/gps_and_location/location.qml"))
        }

        function showEventsSettings() {
            window.showSettingsPage(Qt.resolvedUrl("pages/events/events.qml"))
        }

        function showCallRecordings() {
            window.showSettingsPage(Qt.resolvedUrl("pages/jolla-voicecall/voicecall.qml"), { "showRecordingsImmediately": true })
        }

        function showAddNetworkDialog() {
            window.showSettingsPage(Qt.resolvedUrl("pages/wlan/mainpage.qml"), { "showAddNetworkDialog": true })
        }

        function importOvpn(path) {
            window.showSettingsPage(Qt.resolvedUrl("pages/vpn/mainpage.qml"), { "importPath": path })
        }

        function findBluetoothDevices() {
            window.showSettingsPage(Qt.resolvedUrl("pages/bluetooth/bluetoothSettings.qml"))
            pageStack.currentPage.autoStartDiscovery()
        }

        function newVpnConnection() {
            window.showSettingsPage(Qt.resolvedUrl("pages/vpn/mainpage.qml"))
            pageStack.push(Qt.resolvedUrl("pages/vpn/NewConnectionDialog.qml"), {}, PageStackAction.Immediate)
        }

        function showAmbienceSettings(ambienceContentId) {
            window.showSettingsPage(Qt.resolvedUrl("pages/jolla-gallery-ambience/ambience.qml"), {})
            pageStack.push("com.jolla.gallery.ambience.AmbienceSettingsPage", { "contentId": ambienceContentId }, PageStackAction.Immediate)
        }

        function showPage(page) {
            var obj = _frontPage.model.objectForPath(page)
            if (obj && obj.type == "page") {
                var params = obj.data()["params"]
                if (params["source"]) {
                    window.showSettingsPage(params["source"])
                }
            }
        }

        function activateWindow(arg) {
            window.activate()
        }
    }
}
