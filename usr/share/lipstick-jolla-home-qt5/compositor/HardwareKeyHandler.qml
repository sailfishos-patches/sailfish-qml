import QtQuick 2.6
import Nemo.DBus 2.0
import Nemo.Configuration 1.0
import Sailfish.Media 1.0
import org.nemomobile.systemsettings 1.0

Item {
    readonly property bool hwKeysEnabled: (root.topmostWindow && root.topmostWindow.window.isAlien) || hwButtonsEnabled.value
    readonly property bool appLayerActive: root.appLayer && root.appLayer.active
    readonly property bool suppressKeyEvent: !root._displayOn || root.lockScreenLayer.locked

    function setBackLight(turnOn) {
        mce.buttonBacklight = turnOn
    }

    function defaultAction() {
        if (suppressKeyEvent)
            return

        if (root.topMenuLayer.active) {
            root.topMenuLayer.toggleActive()
        } else {
            root.goToSwitcher(true)
        }
    }

    onHwKeysEnabledChanged: {
        if (deviceInfo.hasFeature(DeviceInfo.FeatureButtonBacklight)) {
            setBackLight(hwKeysEnabled)
        }
    }

    DeviceInfo {
        id: deviceInfo
    }

    DBusInterface {
        id: mce
        bus: DBus.SystemBus
        service: 'com.nokia.mce'
        path: '/com/nokia/mce/request'
        iface: 'com.nokia.mce.request'
        watchServiceStatus: true
        property bool buttonBacklight
        function syncButtonBackLight() {
            if (status == DBusInterface.Available) {
                typedCall("req_button_backlight_change", [{ "type": "b", "value": buttonBacklight}], function() {
                    // success
                }, function() {
                    console.log("Button backlight change attempted by lipstick-jolla-home, failed")
                })
            }
        }
        onButtonBacklightChanged: syncButtonBackLight()
        onStatusChanged: syncButtonBackLight()
    }

    ConfigurationValue {
        id: hwButtonsEnabled
        key: "/desktop/lipstick-jolla-home/sailfish_hw_key_enabled"
        defaultValue: false
    }

    MediaKey {
        key: Qt.Key_HomePage
        enabled: true
        onReleased: defaultAction()
    }

    MediaKey {
        key: Qt.Key_MenuKB
        enabled: true
        onReleased: {
            if (suppressKeyEvent)
                return

            root.topMenuLayer.toggleActive()
        }
    }

    MediaKey {
        key: Qt.Key_Back
        enabled: root.topMenuLayer.active || !appLayerActive
        onReleased: defaultAction()
    }
}
