/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Csd 1.0
import ".."

AutoTest {
    id: test

    function run() {
        check()
    }

    function between(min, value, max) {
        return min <= value && value <= max
    }

    Battery { id: battery }

    property double _MINIMUM_BATTERY_TEMPERATURE_CHARGE: 0      // °C
    property double _MAXIMUM_BATTERY_TEMPERATURE_CHARGE: 45     // °C
    property double _MINIMUM_BATTERY_TEMPERATURE_DISCHARGE: -20 // °C
    property double _MAXIMUM_BATTERY_TEMPERATURE_DISCHARGE: 60  // °C

    property bool batteryPresent: battery.present()

    property double minimumVoltageBat: battery.minimumVoltage()
    property double maximumVoltageBat: battery.maximumVoltage()

    // using default approx limits for Li-Ion/Poly batteries
    property double minimumVoltage: (isNaN(minimumVoltageBat)
                                        // ordinary it can't go even
                                        // below 3.2V on live Li-*
                                        // battery powered system
                                        ? 3 * 1000000
                                        : minimumVoltageBat)
    property double maximumVoltage: (isNaN(maximumVoltageBat)
                                        // for 4x Li-* battery packs
                                        ? 4.2 * 4 * 1000000
                                        : maximumVoltageBat)
    property double voltageNow: battery.voltageNow()
    property bool voltageTestPassed: (CsdHwSettings.batteryVoltageTest && !isNaN(voltageNow)
                                        ? between(minimumVoltage, voltageNow, maximumVoltage)
                                        : true) // property can be absent

    property double minimumEnergy: battery.minimumEnergy()
    property double maximumEnergy: battery.maximumEnergy()
    property double minimumDesignEnergy: battery.minimumDesignEnergy()
    property double maximumDesignEnergy: battery.maximumDesignEnergy()
    property double energyNow: battery.energyNow()
    property bool hasDesignEnergyRange: !(isNaN(maximumDesignEnergy) || isNaN(minimumDesignEnergy))
    property bool hasEnergyRange: !(isNaN(maximumEnergy) || isNaN(minimumEnergy))
    property double energyCapacity: {
        return ((hasDesignEnergyRange && hasEnergyRange &&
                    maximumDesignEnergy !== minimumDesignEnergy)
                ? 100 * (maximumEnergy - minimumEnergy) / (maximumDesignEnergy - minimumDesignEnergy)
                : Number.NaN)
    }
    // Should be comparing against minimumEnergy and maximumEnergy not minimumDesignEnergy and
    // maximumDesignEnergy.
    property bool energyTestPassed: {
        var designEnergyRangeOk = false

        if (!isNaN(energyNow)) {
            var begin, end
            if (hasDesignEnergyRange) {
                begin = minimumDesignEnergy
                end = maximumDesignEnergy
            } else if (hasEnergyRange) {
                begin = minimumEnergy
                end = maximumEnergy
            } else {
                designEnergyRangeOk = true
            }
            designEnergyRangeOk = designEnergyRangeOk || between(begin, energyNow, end)
        } else {
            designEnergyRangeOk = true
        }
        return designEnergyRangeOk && (isNaN(energyCapacity) || energyCapacity >= 75)
    }

    property string health: battery.health()
    property string status: battery.status()
    property double temperature: battery.temperature()
    property bool healthTestPassed: {
        var passed = true
        if (!isNaN(temperature)) {
            if (status === "Charging")
                passed &= between(_MINIMUM_BATTERY_TEMPERATURE_CHARGE, temperature, _MAXIMUM_BATTERY_TEMPERATURE_CHARGE)
            else
                passed &= between(_MINIMUM_BATTERY_TEMPERATURE_DISCHARGE, temperature, _MAXIMUM_BATTERY_TEMPERATURE_DISCHARGE)
        }

        passed &= (["Good", ""].indexOf(health) >= 0)

        return passed
    }

    function check() {
        if (batteryPresent)
            setTestResult(voltageTestPassed && energyTestPassed && healthTestPassed)
        else
            setTestResult(false)
    }
}
