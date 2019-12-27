import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import com.jolla.settings 1.0

SettingsToggle {
    id: root

    //% "Airplane mode"
    name: qsTrId("settings_networking-flight")
    icon.source: "image://theme/icon-m-airplane-mode"

    available: AccessPolicy.flightModeToggleEnabled
    active: flightMode.active
    checked: flightMode.active

    onToggled: {
        if (!AccessPolicy.flightModeToggleEnabled) {
            errorNotification.notify(SettingsControlError.BlockedByAccessPolicy)
        } else {
            busy = true
            flightMode.setActive(!checked)
        }
    }

    FlightMode {
        id: flightMode
        onActiveChanged: {
            root.busy = false
            root.checked = active
        }
    }
}
