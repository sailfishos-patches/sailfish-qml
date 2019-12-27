import QtQml 2.0
import org.nemomobile.dbus 2.0

QtObject {
    id: flashlight

    property bool flashlightOn
    property bool busy

    function handleToggle(available) {
        if (!available) {
            busy = false
        }
    }

    function handleError() {
        console.log("Failed to call method 'toggleFlashlight'.")
        busy = false
    }

    function toggleFlashlight() {
        busy = true
        flashlightDbus.call("toggleFlashlight", undefined, handleToggle, handleError)
    }

    property QtObject flashlightDbus: DBusInterface {
        signalsEnabled: true
        service: "com.jolla.settings.system.flashlight"
        path: "/com/jolla/settings/system/flashlight"
        iface: "com.jolla.settings.system.flashlight"
        function flashlightOnChanged(newOn) {
            busy = false
            flashlight.flashlightOn = newOn
        }
    }

    Component.onCompleted: {
        flashlight.flashlightOn = flashlightDbus.getProperty("flashlightOn")
    }
}
