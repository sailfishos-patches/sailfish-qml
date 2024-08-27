import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Nemo.Ngf 1.0
import com.jolla.settings 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.systemsettings 1.0
import Nemo.Configuration 1.0
import org.nemomobile.lipstick 0.1

Item {
    id: root

    property QtObject slider
    property bool externalChange
    property bool propertiesUpdating
    readonly property bool play: slider.down && !playDelay.running && !volumeControlActive
    property bool volumeControlActive
    property int stepSize: 20
    property int maximumValue: 100
    property alias maximumVolume: volumeControl.maximumVolume

    function updateSliderValue() {
        if (propertiesUpdating) {
            return
        }
        externalChange = true
        slider.value = volumeControlActive ? volumeControl.volume * 10 :
                                          (profileControl.profile == "silent") ? 0 : profileControl.ringerVolume
        externalChange = false
    }

    state: "default"

    states: State {
        name: "default"

        PropertyChanges {
            id: sliderProperties
            readonly property real maxDragX: slider.width - slider.rightMargin - slider._highlightItem.width/2
            readonly property real stepWidth: slider._grooveWidth / volumeControl.maximumVolume
            property bool restrictedMaxDragXBinding: volumeControl.restrictedVolume !== volumeControl.maximumVolume

            target: slider

            // assuming Slider's internal paddings allow label to be nicely shown if a bit extra is reserved
            height: slider.implicitHeight + valueLabel.height + Theme.paddingSmall
            label: volumeControlActive ?
                       //% "Volume"
                       qsTrId("settings_sounds_la_media_volume") :
                       //% "Ringtone volume"
                       qsTrId("settings_sounds_la_volume")
            maximumValue: root.maximumValue
            minimumValue: 0
            stepSize: root.stepSize

            onDownChanged: {
                if (volumeControlActive && sliderProperties.restrictedMaxDragXBinding) {
                    slider.drag.maximumX = Qt.binding(function() {
                        return sliderProperties.maxDragX - sliderProperties.stepWidth * (volumeControl.maximumVolume - volumeControl.currentMax)
                    })
                    sliderProperties.restrictedMaxDragXBinding = false
                }

                if (slider.down) {
                    playDelay.restart()
                }
            }

            onValueChanged: {
                if (!root.externalChange) {
                    root.propertiesUpdating = true  // don't update slider until new values of ringVolume + profile are both known
                    if (volumeControlActive) {
                        volumeControl.volume = slider.value / 10
                    } else {
                        profileControl.ringerVolume = slider.value
                        profileControl.profile = (slider.value > 0) ? "general" : "silent"
                    }
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

    ConfigurationValue {
        key: "/jolla/sound/sw_volume_slider/active"
        value: slider.down
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

        property int scaledVolume: Math.round(slider.value * 10 / maximumVolume)

        parent: root.slider
        slider: root.slider

        //% "%1%"
        text: slider.value > 0 ? qsTrId("settings_sounds-la-percentage_format").arg(volumeControlActive ? scaledVolume : slider.value)
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

    VolumeControl {
        id: volumeControl

        readonly property int currentMax: (restrictedVolume !== maximumVolume) ? restrictedVolume : maximumVolume

        onVolumeChanged: {
            root.updateSliderValue()
        }
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
