/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301 USA
 *
 * http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html
 */

import Nemo.Mce 1.0
import org.freedesktop.contextkit 1.0
import org.freedesktop.contextkit.providers.battery 1.0

ContextPropertyBase {
    id: root

    propertyValue: {
        switch (propertyName) {
        case "ChargePercentage":
            return mceBatteryLevel.percent
        case "Capacity":
            return batteryContext.capacity
        case "Energy":
            return batteryContext.energy
        case "EnergyFull":
            return batteryContext.energyFull
        case "OnBattery":
            return !mceCableState.connected
        case "LowBattery":
            return mceBatteryStatus.status === MceBatteryStatus.Low
        case "TimeUntilLow":
            return batteryContext.timeUntilLow
        case "TimeUntilFull":
            return batteryContext.timeUntilFull
        case "IsCharging":
            return mceBatteryState === MceBatteryState.Charging
        case "Temperature":
            return batteryContext.temperature
        case "Power":
            return batteryContext.power
        case "State":
            switch (mceBatteryStatus.status) {
            case MceBatteryStatus.Full:
                return "full"
            case MceBatteryStatus.Low:
                return "low"
            case MceBatteryStatus.Empty:
                return "empty"
            default:
                return mceBatteryState.text
            }
        case "Voltage":
            return batteryContext.voltage
        case "Current":
            return batteryContext.current
        case "Level":
            return mceBatteryStatus.text
        case "ChargerType":
            return mceChargerType.text
        case "ChargingState":
            return mceBatteryState.text

        default:
            return undefined
        }
    }

    BatteryContextPropertyProvider {
        id: batteryContext

        active: root.subscribed
    }

    MceBatteryLevel {
        id: mceBatteryLevel
    }

    MceBatteryState {
        id: mceBatteryState

        readonly property string text: {
            if (valid) {
                switch (value) {
                case MceBatteryState.Charging:
                    return "charging"
                case MceBatteryState.Discharging:
                    return "discharging"
                case MceBatteryState.NotCharging:
                    return "unknown"
                case MceBatteryState.Full:
                    return "idle"
                }
            }
            return "unknown"
        }
    }

    MceBatteryStatus {
        id: mceBatteryStatus

        readonly property string text: {
            if (valid) {
                switch (status) {
                case MceBatteryStatus.Full:
                case MceBatteryStatus.Ok:
                    return "normal"
                case MceBatteryStatus.Low:
                    return "low"
                case MceBatteryStatus.Empty:
                    return "empty"
                }
            }
            return "unknown"
        }
    }

    MceChargerType {
        id: mceChargerType

        readonly property string text: {
            if (valid) {
                switch (type) {
                case MceChargerType.None:
                    return "None"
                case MceChargerType.USB:
                    return "USB"
                case MceChargerType.DCP:
                    return "DCP"
                case MceChargerType.HVDCP:
                    return "HVDCP"
                case MceChargerType.CDP:
                    return "CDP"
                case MceChargerType.Wireless:
                    return "Wireless"
                case MceChargerType.Other:
                    return "Other"
                }
            }
            return "unknown"
        }
    }

    MceCableState {
        id: mceCableState
    }
}
