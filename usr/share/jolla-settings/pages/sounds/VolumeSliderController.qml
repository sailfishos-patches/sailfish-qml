import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Nemo.Ngf 1.0
import com.jolla.settings 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.systemsettings 1.0

Item {
    id: root

    property QtObject slider
    property bool externalChange
    property bool propertiesUpdating
    readonly property bool play: slider.down && !playDelay.running

    function updateSliderValue() {
        if (propertiesUpdating) {
            return
        }
        externalChange = true
        slider.value = (profileControl.profile == "silent") ? 0 : profileControl.ringerVolume
        externalChange = false
    }

    state: "default"

    states: State {
        name: "default"

        PropertyChanges {
            target: slider

            // assuming Slider's internal paddings allow label to be nicely shown if a bit extra is reserved
            height: slider.implicitHeight + valueLabel.height + Theme.paddingSmall
            //% "Ringtone volume"
            label: qsTrId("settings_sounds_la_volume")
            maximumValue: 100
            minimumValue: 0
            stepSize: 20

            onDownChanged: {
                if (slider.down) {
                    playDelay.restart()
                }
            }

            onValueChanged: {
                if (!root.externalChange) {
                    root.propertiesUpdating = true  // don't update slider until new values of ringVolume + profile are both known
                    profileControl.ringerVolume = slider.value
                    profileControl.profile = (slider.value > 0) ? "general" : "silent"
                    root.propertiesUpdating = false
                }
            }
        }
    }

    onPlayChanged: {
        if (play) {
            feedback.play()
        } else {
            feedback.stop()
        }
    }

    Component.onCompleted: {
        slider.animateValue = false
        root.updateSliderValue()
        slider.animateValue = true
    }

    NonGraphicalFeedback {
        id: feedback
        event: "ringtone"
    }

    Timer {
        id: playDelay
        interval: 1000
    }

    SliderValueLabel {
        id: valueLabel

        parent: root.slider
        slider: root.slider

        //% "%1%"
        text: slider.value > 0 ? qsTrId("settings_sounds-la-percentage_format").arg(slider.value)
                               : ""
        scale: slider.pressed ? Theme.fontSizeLarge / Theme.fontSizeMedium : 1.0
        font.pixelSize: Theme.fontSizeMedium
    }

    HighlightImage {
        x: valueLabel.x + (valueLabel.width / 2) - (width / 2)
        y: valueLabel.y + (valueLabel.height / 2) - (height / 2)
        source: "image://theme/icon-status-silent"
        highlighted: slider.highlighted
        visible: slider.value === 0
        scale: slider.down ? Theme.fontSizeLarge / Theme.fontSizeMedium : 1.0
        Behavior on scale { NumberAnimation { duration: 80 } }
    }

    ProfileControl {
        id: profileControl

        onRingerVolumeChanged: {
            root.updateSliderValue()
        }

        onProfileChanged: {
            root.updateSliderValue()
        }
    }
}
