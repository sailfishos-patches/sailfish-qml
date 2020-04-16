import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.systemsettings 1.0
import org.nemomobile.configuration 1.0
import org.nemomobile.lipstick 0.1
import Nemo.Notifications 1.0

Page {
    id: page

    SilicaFlickable {

        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content

            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                //% "Gestures"
                title: qsTrId("settings_display-he-gestures")
            }

            SectionHeader {
                //% "Edge swipes"
                text: qsTrId("settings_shortcuts-la-edge_swipes")
            }

            TextSwitch {
                automaticCheck: false
                checked: desktopSettings.left_peek_to_events
                //% "Quick Events access"
                text: qsTrId("settings_display-la-left_peek_at_events")
                //% "A left edge swipe always goes to Events instead of Home"
                description: qsTrId("settings_shortcuts-la-left_peek_at_events_hint")
                onClicked: desktopSettings.left_peek_to_events = !desktopSettings.left_peek_to_events
            }

            TextSwitch {
                automaticCheck: false
                checked: desktopSettings.lock_screen_camera
                //% "Quick access to Camera"
                text: qsTrId("settings_display-la-quick_access_to_camera")
                //% "A bottom edge swipe opens the Camera app from the lock screen"
                description: qsTrId("settings_shortcuts-la-quick_access_to_camera_hint")
                onClicked: desktopSettings.lock_screen_camera = !desktopSettings.lock_screen_camera
            }

            SectionHeader {
                //% "Sensor gestures"
                text: qsTrId("settings_shortcuts-la-sensor_gestures")
            }

            TextSwitch {
                automaticCheck: false
                checked: displaySettings.flipoverGestureEnabled
                //% "Flip to silence calls and alarms"
                text: qsTrId("settings_display-la-flip_to_silence")
                onClicked: displaySettings.flipoverGestureEnabled = !displaySettings.flipoverGestureEnabled

                //% "Turn the device face down to mute incoming call ringtones and alarm alerts"
                description: qsTrId("settings_display-la-flip_to_silence_description")
            }

            SectionHeader {
                //% "Hints and tips"
                text: qsTrId("settings_shortcuts-he-hints_and_tips")
            }

            ListItem {
                id: hintsItem

                contentHeight: hintsSwitch.height + Theme.paddingMedium
                TextSwitch {
                    id: hintsSwitch
                    //% "Show hints and tips"
                    text: qsTrId("settings_shortcuts-la-show_hints_and_tips")
                    //% "Animated hints are often played when you use an app or a feature for the first time"
                    description: qsTrId("settings_shortcuts-la-animated_hints_first_time")
                    automaticCheck: false
                    checked: hintsEnabled.value
                    onClicked: hintsEnabled.value = !hintsEnabled.value
                    onPressAndHold: hintsItem.openMenu()
                }

                ConfigurationValue {
                    id: hintsEnabled
                    key: "/desktop/sailfish/silica/hints_enabled"
                    defaultValue: true
                }

                menu: Component {
                    ContextMenu {
                        MenuItem {
                            //% "Reset hints"
                            text: qsTrId("settings_shortcuts-me-reset_hints")
                            onDelayedClick: hintReset.reset()
                        }
                    }
                }

                ConfigurationValue {
                    id: hintReset
                    function reset() {
                        for (var i = 0; i < hints.length; i++) {
                            key = hints[i]
                            value = 0
                        }
                        //% "Resetting some hints may require a reboot"
                        notification.previewBody = qsTrId("settings_shortcuts-la-reseting_may_require_reboot")
                        notification.publish()
                    }

                    property var hints: [
                        // JB#46278: Restructure hint keys so reseting is easier
                        "/desktop/lipstick-jolla-home/close_all_apps_hint_count",
                        "/desktop/sailfish/hints/close_app_hint_count",
                        "/desktop/sailfish/hints/coordination_state",
                        "/desktop/sailfish/hints/return_to_home_hint_count",
                        "/desktop/sailfish/hints/remorse_swipe_hint_count",
                        "/desktop/sailfish/hints/remorse_disappear_hint_count",
                        "/sailfish/accounts/settings_autosave_hint_count",
                        "/sailfish/calculator/scientific_calculator_hint_count",
                        "/sailfish/calendar/change_month_hint_count",
                        "/sailfish/camera/camera_mode_hint_count",
                        "/sailfish/camera/camera_roll_hint_count",
                        "/sailfish/email/folder_access_hint_count",
                        "/sailfish/gallery/vertical_page_back_hint",
                        "/sailfish/maps/explore_map_hint_count",
                        "/sailfish/messages/access_contact_card_hint_count",
                        "/sailfish/store/categories_attached_page_hint_count",
                        "/sailfish/store/download_upgrade_hint_count",
                        "/sailfish/text_input/switch_keyboard_hint_count",
                        "/sailfish/text_input/close_keyboard_hint_count",
                        "/sailfish/text_input/close_keyboard_hint_date",
                        "/sailfish/voicecall/incoming_call_hint_count",
                        "/sailfish/weather/pull_down_to_add_another_location_hint_count"
                    ]
                }
            }
        }
    }

    ConfigurationGroup {
        id: desktopSettings
        path: "/desktop/lipstick-jolla-home"

        property bool left_peek_to_events: false
        property bool lock_screen_camera: true
    }

    DisplaySettings { id: displaySettings }

    Notification {
        id: notification

        icon: "icon-system-warning"
        isTransient: true
    }
}
