import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.systemsettings 1.0

Page {
    SilicaFlickable {

        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        function qsTrIdStrings() {
            //% "15 seconds"
            QT_TRID_NOOP("settings_display-me-15_seconds")
            //% "30 seconds"
            QT_TRID_NOOP("settings_display-me-30_seconds")
            //% "1 minute"
            QT_TRID_NOOP("settings_display-me-1_minute")
            //% "2 minutes"
            QT_TRID_NOOP("settings_display-me-2_minutes")
            //% "5 minutes"
            QT_TRID_NOOP("settings_display-me-5_minutes")
            //% "10 minutes"
            QT_TRID_NOOP("settings_display-me-10_minutes")
            //% "Dynamic"
            QT_TRID_NOOP("settings_display-me-dynamic")
            //% "Portrait"
            QT_TRID_NOOP("settings_display-me-portrait")
            //% "Landscape"
            QT_TRID_NOOP("settings_display-me-landscape")
        }

        VerticalScrollDecorator {}

        ListModel {
            id: timeoutModel
            ListElement {
                label: "settings_display-me-15_seconds"
                value: 15
            }
            ListElement {
                label: "settings_display-me-30_seconds"
                value: 30
            }
            ListElement {
                label: "settings_display-me-1_minute"
                value: 60
            }
            ListElement {
                label: "settings_display-me-2_minutes"
                value: 120
            }
            ListElement {
                label: "settings_display-me-10_minutes"
                value: 600
            }
        }

        ListModel {
            id: orientationLockModel
            ListElement {
                label: "settings_display-me-dynamic"
                value: "dynamic"
            }
            ListElement {
                label: "settings_display-me-portrait"
                value: "portrait"
            }
            ListElement {
                label: "settings_display-me-landscape"
                value: "landscape"
            }
        }

        Column {
            id: content

            width: parent.width

            PageHeader {
                //% "Display"
                title: qsTrId("settings_display-he-display")
            }

            BrightnessSlider {
                width: parent.width
            }

            TextSwitch {
                id: adaptiveDimmingSwitch
                visible: deviceInfo.hasFeature(DeviceInfo.FeatureLightSensor)
                automaticCheck: false
                checked: displaySettings.ambientLightSensorEnabled && displaySettings.autoBrightnessEnabled
                //% "Adaptive Brightness"
                text: qsTrId("settings_display-la-adaptive_brightness")
                onClicked: {
                    if (checked) {
                        displaySettings.autoBrightnessEnabled = false
                    } else {
                        displaySettings.autoBrightnessEnabled = true
                        displaySettings.ambientLightSensorEnabled = true
                    }
                }
            }

            /*
            TextSwitch {
                automaticCheck: false
                checked: displaySettings.lowPowerModeEnabled
                //% "Sneak Peek"
                text: qsTrId("settings_display-la-sneak_peek")
                onClicked: displaySettings.lowPowerModeEnabled = !displaySettings.lowPowerModeEnabled

                //% "Automatically show time and status information when taking the device out of pocket."
                description: qsTrId("settings_display-la-sneak_peek_description")
            }
            */

            ComboBox {
                id: dimCombo
                onCurrentIndexChanged: displaySettings.dimTimeout = timeoutModel.get(currentIndex).value

                //% "Blank display after"
                label: qsTrId("settings_display-la-blank_display_after")
                menu: ContextMenu {
                    Repeater {
                        model: timeoutModel
                        MenuItem {
                            text: qsTrId(label)
                        }
                    }
                }
            }

            TextSwitch {
                automaticCheck: false
                checked: displaySettings.inhibitMode === DisplaySettings.InhibitStayOnWithCharger
                //% "Keep display on while charging"
                text: qsTrId("settings_display-la-display_on_charger")
                onClicked: displaySettings.inhibitMode = checked ? DisplaySettings.InhibitOff : DisplaySettings.InhibitStayOnWithCharger

                //% "Prevent the display from blanking while the charger is connected"
                description: qsTrId("settings_display-la-display_on_charger_description")
            }

            TextSwitch {
                id: lidSensorSwitch
                visible: deviceInfo.hasFeature(DeviceInfo.FeatureCoverSensor)
                automaticCheck: false
                checked: displaySettings.lidSensorEnabled
                //% "Use flip cover to control display"
                text: qsTrId("settings_display-la-lid_sensor")
                onClicked: displaySettings.lidSensorEnabled = !displaySettings.lidSensorEnabled

                //% "Automatically turn display on or off when magnetic flip cover is opened or closed"
                description: qsTrId("settings_display-la-lid_sensor_description")
            }

            SectionHeader {
                //% "Orientation"
                text: qsTrId("settings_display-he-orientation")
            }

            ComboBox {
                id: orientationLockCombo

                // postpone change until menu is closed so that transition doesn't happen during orientation change
                property int pendingChange: -1
                onCurrentIndexChanged: {
                    pendingChange = currentIndex
                    changeTimer.restart()
                }

                //% "Orientation"
                label: qsTrId("settings_display-la-orientation")
                menu: ContextMenu {
                    onClosed: orientationLockCombo.applyChange()

                    Repeater {
                        model: orientationLockModel
                        MenuItem {
                            text: qsTrId(label)
                        }
                    }
                }
                //% "If you want to disable orientation switching temporarily, select the Dynamic option and keep your finger on the screen while turning the device."
                description: qsTrId("settings_display-la-orientation_dynamic")

                function applyChange() {
                    changeTimer.stop()
                    if (orientationLockCombo.pendingChange >= 0) {
                        displaySettings.orientationLock = orientationLockModel.get(orientationLockCombo.pendingChange).value
                        orientationLockCombo.pendingChange = -1
                    }
                }

                Timer {
                    id: changeTimer
                    interval: 1000
                    onTriggered: orientationLockCombo.applyChange()
                }
            }

            SectionHeader {
                //% "Fonts"
                text: qsTrId("settings_display-he-fonts")
            }

            ComboBox {
                id: fontSizeComboBox
                FontSizeSetting {
                    id: fontSizeSetting
                }

                currentIndex: fontSizeSetting.currentIndex

                //% "Text size"
                label: qsTrId("settings_display-la-text-size")
                menu: ContextMenu {
                    Repeater {
                        model: fontSizeSetting.categoryNames
                        MenuItem {
                            text: modelData
                            onDelayedClick: fontSizeSetting.update(index)
                        }
                    }
                }
            }
        }
    }
    DisplaySettings {
        id: displaySettings
        function timeoutIndex(value) {
            for (var i = 0; i < timeoutModel.count; ++i) {
                if (value <= timeoutModel.get(i).value) {
                    return i
                }
            }
            return timeoutModel.count-1
        }
        function orientationLockIndex(value) {
            for (var i = 0; i < orientationLockModel.count; ++i) {
                if (value == orientationLockModel.get(i).value) {
                    return i
                }
            }
            return 0
        }
        onDimTimeoutChanged: dimCombo.currentIndex = timeoutIndex(dimTimeout)
        onOrientationLockChanged: orientationLockCombo.currentIndex = orientationLockIndex(orientationLock)
        Component.onCompleted: {
            dimCombo.currentIndex = timeoutIndex(dimTimeout)
            orientationLockCombo.currentIndex = orientationLockIndex(orientationLock)
        }
    }
    DeviceInfo {
        id: deviceInfo
    }
}
