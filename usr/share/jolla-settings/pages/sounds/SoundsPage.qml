import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.systemsettings 1.0
import Nemo.Configuration 1.0
import QtFeedback 5.0

Page {
    ProfileControl { id: soundSettings }

    ThemeEffect {
        id: feedbackEffect
    }

    SilicaFlickable {
        id: listView

        anchors.fill: parent
        contentHeight: content.height + Theme.paddingMedium

        Column {
            id: content

            width: parent.width
            anchors.left: parent.left
            anchors.right: parent.right

            PageHeader {
                //% "Sounds"
                title: qsTrId("settings_sounds-he-sounds")
            }

            ComboBox {
                id: vibraComboBox

                visible: feedbackEffect.supported
                width: parent.width
                //% "Vibrate"
                label: qsTrId("settings_sounds-la-vibrate_combobox")
                currentIndex: modeToIndex(soundSettings.vibraMode)

                menu: ContextMenu {
                    MenuItem {
                        property int mode: ProfileControl.VibraAlways
                        //% "Always"
                        text: qsTrId("settings_sounds-me-vibrate_always")
                    }
                    MenuItem {
                        property int mode: ProfileControl.VibraSilent
                        //% "Only when silent"
                        text: qsTrId("settings_sounds-me-vibrate_silent")
                    }
                    MenuItem {
                        property int mode: ProfileControl.VibraNormal
                        //% "Only when sounds on"
                        text: qsTrId("settings_sounds-me-vibrate_sounds_on")
                    }
                    MenuItem {
                        property int mode: ProfileControl.VibraNever
                        //% "Never"
                        text: qsTrId("settings_sounds-me-vibrate_never")
                    }
                }
                onCurrentItemChanged: {
                    if (currentItem) {
                        soundSettings.vibraMode = currentItem.mode
                    }
                }

                function modeToIndex(mode) {
                    switch (mode) {
                    case ProfileControl.VibraAlways:
                        return 0
                    case ProfileControl.VibraSilent:
                        return 1
                    case ProfileControl.VibraNormal:
                        return 2
                    case ProfileControl.VibraNever:
                        return 3
                    default:
                        return -1
                    }
                }


                Connections {
                    target: soundSettings
                    onVibraModeChanged: vibraComboBox.currentIndex = vibraComboBox.modeToIndex(soundSettings.vibraMode)
                }
            }

            RingtoneVolumeSlider {
                width: parent.width
            }

            VolumeSlider {
                width: parent.width
            }

            Item {
                width: parent.width
                height: Theme.paddingLarge
            }

            SectionHeader {
                //% "Tones"
                text: qsTrId("settings_sounds-la-tones")
            }

            Tones {
                toneSettings: soundSettings
            }

            // Feedbacks
            SectionHeader {
                //% "Feedback"
                text: qsTrId("settings_sounds-la-feedback")
            }

            TextSwitch {
                automaticCheck: false
                checked: soundSettings.systemSoundLevel !== 0
                //% "System sounds"
                text: qsTrId("settings_sounds-la-system_sounds")
                //% "Plays sound on battery low or other system notifications"
                description: qsTrId("settings_sounds-la-system_sounds_description")
                onClicked: soundSettings.systemSoundLevel = !soundSettings.systemSoundLevel
            }

            TextSwitch {
                automaticCheck: false
                checked: soundSettings.touchscreenToneLevel !== 0
                //% "Touch screen tones"
                text: qsTrId("settings_sounds-la-touch_screen_tones")
                //% "Plays sound when action is made on touch screen"
                description: qsTrId("settings_sounds-la-touch_screen_tones_description")
                onClicked: soundSettings.touchscreenToneLevel = !soundSettings.touchscreenToneLevel
            }

            TextSwitch {
                visible: feedbackEffect.supported
                automaticCheck: false
                checked: soundSettings.touchscreenVibrationLevel !== 0
                //% "Touch screen feedback"
                text: qsTrId("settings_sounds-la-touch_screen_feedback")
                //% "Vibrates when action is made on touch screen"
                description: qsTrId("settings_sounds-la-touch_screen_feedback_description")
                onClicked: soundSettings.touchscreenVibrationLevel = !soundSettings.touchscreenVibrationLevel
            }

            SectionHeader {
                //% "Do not disturb mode"
                text: qsTrId("settings_sounds-la-do_not_disturb")
            }
            TextSwitch {
                automaticCheck: false
                checked: !!doNotDisturb.value
                //% "Enable do not disturb mode"
                text: qsTrId("settings_sounds-la-enable_do_not_disturb")
                //% "When on, the notifications will not play sound or feedback"
                description: qsTrId("settings_sounds-la-do_not_disturb_description")
                onClicked: doNotDisturb.value = !doNotDisturb.value
            }

            ComboBox {
                id: dndRingtoneCombobox

                //% "Ringtone for incoming calls"
                label: qsTrId("settings_sounds-la-do_not_disturb_ringtone")
                menu: ContextMenu {
                    MenuItem {
                        property string value: "off"
                        //: No ringtone on incoming calls on do no disturb mode
                        //% "Off"
                        text: qsTrId("settings_sounds-la-do_not_disturb_ringtone_off")
                    }
                    MenuItem {
                        property string value: "favorites"
                        //: Favorite contacts have ringtone on incoming calls on do no disturb mode
                        //% "Only favorite contacts"
                        text: qsTrId("settings_sounds-la-do_not_disturb_ringtone_favorites")
                    }
                    MenuItem {
                        property string value: "contacts"
                        //: Known contacts have ringtone on incoming calls on do no disturb mode
                        //% "Only contacts"
                        text: qsTrId("settings_sounds-la-do_not_disturb_ringtone_contacts")
                    }
                    MenuItem {
                        property string value: "on"
                        //: Ringtone plays on incoming calls on do no disturb mode
                        //% "On"
                        text: qsTrId("settings_sounds-la-do_not_disturb_ringtone_on")
                    }
                }

                //% "Allow some incoming calls to play ringtones as exceptions to ‘Do not disturb’ mode"
                description: qsTrId("settings_sounds-la-do_not_disturb_ringtone_exceptions")

                onCurrentItemChanged: {
                    if (currentItem) {
                        doNotDisturbRingtone.value = currentItem.value
                    }
                }
                Component.onCompleted: updateIndex()


                function updateIndex() {
                    currentIndex = valueToIndex(doNotDisturbRingtone.value)
                }

                function valueToIndex(config) {
                    switch(config) {
                    case "off":
                        return 0
                    case "favorites":
                        return 1
                    case "contacts":
                        return 2
                    case "on":
                    case "default":
                        return 3
                    }
                }
            }

            ConfigurationValue {
                id: doNotDisturb
                defaultValue: false
                key: "/lipstick/do_not_disturb"
            }

            ConfigurationValue {
                id: doNotDisturbRingtone

                defaultValue: "on"
                key: "/lipstick/do_not_disturb_ringtone"
                onValueChanged: dndRingtoneCombobox.updateIndex()
            }
        }
        VerticalScrollDecorator {}
    }
}
