import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings 1.0
import com.jolla.settings.system 1.0

SettingsToggle {
    id: root

    //% "Flashlight"
    name: qsTrId("settings_system-flashlight")
    icon.source: "image://theme/icon-m-flashlight"

    busy: flashlight.busy
    checked: flashlight.flashlightOn
    onToggled: flashlight.toggleFlashlight()

    Flashlight {
        id: flashlight
    }
}
