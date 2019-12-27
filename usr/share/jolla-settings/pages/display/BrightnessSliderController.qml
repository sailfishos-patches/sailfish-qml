import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings 1.0
import org.nemomobile.systemsettings 1.0

Item {
    id: root

    property QtObject slider

    state: "default"

    states: State {
        name: "default"

        PropertyChanges {
            target: slider

            //% "Brightness"
            label: qsTrId("settings_display-la-brightness")
            maximumValue: displaySettings.maximumBrightness
            minimumValue: 1
            value: displaySettings.brightness
            stepSize: 1

            onValueChanged: {
                displaySettings.brightness = Math.round(value)
            }
        }
    }

    DisplaySettings {
        id: displaySettings
        onBrightnessChanged: slider.value = brightness
    }
}
