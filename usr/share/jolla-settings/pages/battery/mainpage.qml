/*
 * Copyright (C) 2018 Jolla Ltd.
 */
import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0

Page {
    id: root

    // TODO: This list should be queried from mce. The related setting
    // is /system/osso/dsm/energymanagement/possible_psm_thresholds
    readonly property var thresholdOptions: [-1, 5, 10, 15, 20]

    readonly property int effectivePowerSaveModeThreshold: displaySettings.powerSaveModeEnabled ? displaySettings.powerSaveModeThreshold : -1

    function thresholdText(threshold) {
        if (threshold < 0 ) {
            //% "Not in use"
            return qsTrId("settings_battery-la-battery_saving_mode_not_in_use")
        }
        //% "Battery %1%"
        return qsTrId("settings_battery-la-battery_level").arg(Math.min(threshold, 100))
    }
    function setThreshold(threshold) {
        if (threshold < 0) {
            displaySettings.powerSaveModeEnabled = false
        } else {
            displaySettings.powerSaveModeThreshold = threshold
            displaySettings.powerSaveModeEnabled = true
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingMedium

        Column {
            id: content

            width: parent.width

            PageHeader {
                //% "Battery"
                title: qsTrId("settings_system-he-battery")
            }

            IconTextSwitch {
                icon.source: "image://theme/icon-m-battery-saver"
                automaticCheck: false
                checked: displaySettings.powerSaveModeForced
                //% "Enable battery saving mode until charger is connected the next time"
                text: qsTrId("settings_battery-la-battery-saving-mode-enabled")
                //% "Battery saving mode will adjust the device behaviour to help improve battery life. "
                //% "It may disable email and calendar sync, lower display brightness etc."
                description: qsTrId("settings_battery-la-battery-saving-mode-enabled_description")
                onClicked: displaySettings.powerSaveModeForced = !displaySettings.powerSaveModeForced
            }

            SectionHeader {
                //% "Automatic battery saving"
                text: qsTrId("settings_battery-la-automatic_battery_saving")
            }

            ComboBox {
                id: thresholdComboBox

                value: thresholdText(effectivePowerSaveModeThreshold)
                //% "Activation threshold"
                label: qsTrId("settings_battery-la-battery_saving_threshold")
                //% "Set threshold for automatically enabling battery saving mode."
                description: qsTrId("settings_battery-la-power_saving_mode_threshold_description")

                Binding {
                    target: thresholdComboBox
                    property: "currentIndex"
                    value: root.thresholdOptions.indexOf(effectivePowerSaveModeThreshold)
                }

                menu: ContextMenu {
                    Repeater {
                        model: root.thresholdOptions
                        MenuItem {
                            text: thresholdText(modelData)
                            onClicked: setThreshold(modelData)
                        }
                    }
                }
            }
        }
    }

    DisplaySettings {
        id: displaySettings
    }
}
