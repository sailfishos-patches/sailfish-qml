import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.systemsettings 1.0

Slider {
    id: slider

    BrightnessSliderController {
        slider: slider
    }
}
