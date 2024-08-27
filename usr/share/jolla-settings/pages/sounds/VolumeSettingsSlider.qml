import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings 1.0

SettingsControl {
    id: root

    contentHeight: slider.height

    VolumeSliderController {
        slider: slider
        volumeControlActive: true
        stepSize: 10
        maximumValue: maximumVolume * stepSize
    }

    SettingsSlider {
        id: slider

        width: root.width

        onPressAndHold: {
            slider.cancel()
            root.openMenu()
        }
    }
}
