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

    readonly property var chargingModeOptions: [BatteryStatus.EnableCharging,
                                                //BatteryStatus.DisableCharging,
                                                BatteryStatus.ApplyChargingThresholds,
                                                //BatteryStatus.ApplyChargingThresholdsAfterFull,
                                               ]
    property alias chargingThresholdsSupported: batteryStatus.chargingSuspendendable
    readonly property var chargingThresholdOptions: [80, 90]
    readonly property int chargingThresholdDelta: 3
    readonly property bool chargingThresholdsAreValid: batteryStatus.chargeEnableLimit < batteryStatus.chargeDisableLimit
    readonly property bool chargingThresholdsAreSimple: batteryStatus.chargeEnableLimit + chargingThresholdDelta == batteryStatus.chargeDisableLimit
    readonly property bool chargingThresholdsAreRelevant: (batteryStatus.chargingMode == BatteryStatus.ApplyChargingThresholds
                                                           || batteryStatus.chargingMode== BatteryStatus.ApplyChargingThresholdsAfterFull)
    readonly property bool forcedChargingIsRelevant: (batteryStatus.chargerStatus == BatteryStatus.Connected
                                                      && batteryStatus.status != BatteryStatus.Full
                                                      && batteryStatus.chargingMode != BatteryStatus.EnableCharging)
    property alias forcedChargingIsActive: batteryStatus.chargingForced

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

    function chargingModeText(mode) {
        if (mode == BatteryStatus.EnableCharging) {
            //% "Normal"
            return qsTrId("settings_battery-la-charging_always_enabled")
        }
        if (mode == BatteryStatus.DisableCharging) {
            //% "Disabled"
            return qsTrId("settings_battery-la-charging_always_disabled")
        }
        if (mode == BatteryStatus.ApplyChargingThresholds) {
            //% "Apply thresholds"
            return qsTrId("settings_battery-la-charging_apply_thresholds")
        }
        if (mode == BatteryStatus.ApplyChargingThresholdsAfterFull) {
            //% "Charge to full, then apply thresholds"
            return qsTrId("settings_battery-la-charging_apply_thresholds_after_full")
        }
        //% "Unknown"
        return qsTrId("settings_battery-la-charging_unknown_mode")
    }
    function chargingModeDescription(mode) {
        if (mode == BatteryStatus.EnableCharging) {
            //% "Charge whenever a charger is connected"
            return qsTrId("settings_battery-la-charging_always_enabled_description")
        }
        if (mode == BatteryStatus.DisableCharging) {
            //% "Charge only when battery is close to empty"
            return qsTrId("settings_battery-la-charging_always_disabled_description")
        }
        if (mode == BatteryStatus.ApplyChargingThresholds
           || mode == BatteryStatus.ApplyChargingThresholdsAfterFull) {
            if (chargingThresholdsAreSimple) {
                //% "Stop charging at specified value"
                return qsTrId("settings_battery-la-charging_apply_thresholds_description_value")
            }
            //% "Keep battery level within specified range"
            return qsTrId("settings_battery-la-charging_apply_thresholds_description_range")
        }
        return ""
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

            SectionHeader {
                //% "Battery saving mode"
                text: qsTrId("settings_battery-la-battery_saving_mode")
            }

            ComboBox {
                id: thresholdComboBox

                value: thresholdText(effectivePowerSaveModeThreshold)
                //% "Activation threshold"
                label: qsTrId("settings_battery-la-battery_saving_threshold")
                //% "Battery saving mode will adjust the device behaviour to help improve battery life. "
                //% "It may disable email and calendar sync, lower display brightness etc."
                description: qsTrId("settings_battery-la-battery_saving_threshold_description")

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

            IconTextSwitch {
                icon.source: "image://theme/icon-m-battery-saver"
                automaticCheck: false
                checked: displaySettings.powerSaveModeForced
                //% "Enable battery saving mode until charger is connected the next time"
                text: qsTrId("settings_battery-la-battery-saving-mode-forced")
                //% "Temporarily enable battery saving mode regardless of the activation threshold"
                description: qsTrId("settings_battery-la-battery-saving-mode-forced_description")
                onClicked: displaySettings.powerSaveModeForced = !displaySettings.powerSaveModeForced
            }

            SectionHeader {
                visible: chargingThresholdsSupported
                //% "Battery ageing protection"
                text: qsTrId("settings_battery-la-battery_ageing_protection")
            }

            ComboBox {
                id: chargingModeComboBox
                visible: chargingThresholdsSupported
                //% "Charging mode"
                label: qsTrId("settings_battery-la-charging_mode")
                value: chargingModeText(batteryStatus.chargingMode)
                description: chargingModeDescription(batteryStatus.chargingMode)
                Binding {
                    target: chargingModeComboBox
                    property: "currentIndex"
                    value: root.chargingModeOptions.indexOf(batteryStatus.chargingMode)
                }
                menu: ContextMenu {
                    Repeater {
                        model: root.chargingModeOptions
                        MenuItem {
                            text: chargingModeText(modelData)
                            onClicked: batteryStatus.chargingMode = modelData
                        }
                    }
                }
            }

            ComboBox {
                id: chargingThresholdsComboBox
                value: {
                    if (chargingThresholdsAreSimple) {
                        return "%1%".arg(batteryStatus.chargeDisableLimit)
                    }
                    return "%1% - %2%".arg(batteryStatus.chargeEnableLimit).arg(batteryStatus.chargeDisableLimit)
                }
                label: {
                    if (chargingThresholdsAreSimple) {
                        //% "Stop charging at"
                        return qsTrId("settings_battery-la-charging_disable_limit")
                    }
                    //% "Keep in range"
                    return qsTrId("settings_battery-la-charging_keep_in_range")
                }
                visible: chargingThresholdsSupported && chargingThresholdsAreRelevant
                valueColor: chargingThresholdsAreValid ? Theme.highlightColor : "red"
                Binding {
                    target: chargingThresholdsComboBox
                    property: "currentIndex"
                    value: root.chargingThresholdOptions.indexOf(batteryStatus.chargeDisableLimit)
                }
                menu: ContextMenu {
                    Repeater {
                        model: root.chargingThresholdOptions
                        MenuItem {
                            text: "%1%".arg(modelData)
                            onClicked: {
                                batteryStatus.chargeDisableLimit = modelData
                                batteryStatus.chargeEnableLimit = modelData - chargingThresholdDelta
                            }
                        }
                    }
                }
            }

            IconTextSwitch {
                icon.source: "image://theme/icon-m-battery"
                automaticCheck: false
                visible: chargingThresholdsSupported && forcedChargingIsRelevant
                checked: forcedChargingIsActive
                //% "Fully charge this time"
                text: qsTrId("settings_battery-la-apply-charging-thresholds-after-full")
                //% "Temporarily suppress battery ageing protection to fully charge the battery once"
                description: qsTrId("settings_battery-la-apply-charging-thresholds-after-full_description")
                onClicked: forcedChargingIsActive = !forcedChargingIsActive
            }
        }
    }

    DisplaySettings {
        id: displaySettings
    }

    BatteryStatus {
        id: batteryStatus
    }
}
