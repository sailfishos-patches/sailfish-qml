import QtQuick 2.0
import Sailfish.Silica 1.0

Slider {
    id: slider

    VolumeSliderController {
        slider: slider
        volumeControlActive: true
        stepSize: 10
        maximumValue: maximumVolume * stepSize
    }
}
