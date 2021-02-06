import QtQuick 2.6
import Sailfish.Silica 1.0
import com.jolla.settings 1.0
import org.nemomobile.configuration 1.0

SettingsToggle {
    //% "Do not disturb"
    name: qsTrId("settings_sound-la-do_not_disturb")
    icon.source: "image://theme/icon-m-do-not-disturb"
    checked: !!doNotDisturbConfig.value
    onToggled: {
        doNotDisturbConfig.value = !doNotDisturbConfig.value
    }

    ConfigurationValue {
        id: doNotDisturbConfig
        defaultValue: false
        key: "/lipstick/do_not_disturb"
    }
}
