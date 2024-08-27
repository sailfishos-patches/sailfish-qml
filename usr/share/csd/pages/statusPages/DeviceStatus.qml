/*
 * Copyright (c) 2014 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Csd 1.0
import Nemo.Time 1.0
import Nemo.DBus 2.0

Page {
    id: page

    SilicaFlickable {
        anchors.fill: parent

        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            PageHeader {
                //% "Device status"
                title: qsTrId("csd-he-device_status")
            }

            SectionHeader {
                //% "Temperature"
                text: qsTrId("csd-he-temparature")
            }

            Label {
                //% "Surface: %1"
                text: qsTrId("csd-la-surface_temperature").arg(thermalManager.surfaceTemperature + "°C")
                x: Theme.paddingLarge
                visible: thermalManager.surfaceTemperature !== thermalManager.invalidTemperature
            }

            Label {
                //% "Core: %1"
                text: qsTrId("csd-la-core_temperature").arg(thermalManager.coreTemperature + "°C")
                x: Theme.paddingLarge
                visible: thermalManager.coreTemperature !== thermalManager.invalidTemperature
            }

            Label {
                //% "Battery: %1"
                text: qsTrId("csd-la-battery_temperature").arg(thermalManager.batteryTemperature + "°C")
                x: Theme.paddingLarge
                visible: thermalManager.batteryTemperature !== thermalManager.invalidTemperature
            }

            Label {
                //% "System: %1"
                text: qsTrId("csd-la-system_temperature").arg(thermalManager.systemTemperature + "°C")
                x: Theme.paddingLarge
                visible: thermalManager.systemTemperature !== thermalManager.invalidTemperature
            }

            SectionHeader {
                //% "Uptime"
                text: qsTrId("csd-he-uptime")
            }

            Label {
                //% "Up for %0"
                text: qsTrId("csd-la-up-for").arg(Format.formatDuration(uptimeClock.uptime / 1000, Format.DurationLong))
                x: Theme.paddingLarge
            }

            SectionHeader {
                //% "Load average"
                text: qsTrId("csd-he-load_average")
            }

            Label {
                //% "%0 minute(s) for %1"
                text: qsTrId("csd-la-minutes").arg(1).arg(uptime.loadAverage1.toFixed(2))
                x: Theme.paddingLarge
            }
            Label {
                //% "%0 minute(s) for %1"
                text: qsTrId("csd-la-minutes").arg(5).arg(uptime.loadAverage5.toFixed(2))
                x: Theme.paddingLarge
            }
            Label {
                //% "%0 minute(s) for %1"
                text: qsTrId("csd-la-minutes").arg(15).arg(uptime.loadAverage15.toFixed(2))
                x: Theme.paddingLarge
            }

            SectionHeader {
                //% "Power"
                text: qsTrId("csd-he-power")
                visible: !isNaN(battery.current)
            }

            Label {
                //% "Current (mA): %0"
                text: qsTrId("csd-la-current-milliampere").arg(Math.round(battery.current/1000).toFixed())
                x: Theme.paddingLarge
                visible: !isNaN(battery.current)
            }
        }
    }

    Uptime {
        id: uptime
    }

    Battery {
        id: battery

        property double current: Number.NaN
    }

    Timer {
        interval: 1000
        repeat: true
        running: page.status === PageStatus.Active
        triggeredOnStart: true

        onTriggered: battery.current = battery.currentNow()
    }

    WallClock {
        id: uptimeClock

        property int uptime: time - uptime.machineStart
        updateFrequency: WallClock.Second
    }

    DBusInterface {
        id: thermalManager

        readonly property int invalidTemperature: -9999

        property int surfaceTemperature: invalidTemperature
        property int coreTemperature: invalidTemperature
        property int batteryTemperature: invalidTemperature
        property int systemTemperature: invalidTemperature

        service: "com.nokia.thermalmanager"
        iface: "com.nokia.thermalmanager"
        path: "/com/nokia/thermalmanager"
        bus: DBus.SystemBus
    }

    Timer {
        interval: 5000
        triggeredOnStart: true
        repeat: true
        running: Qt.application.active
        onTriggered: {
            thermalManager.typedCall("estimate_surface_temperature", [], function(r) { thermalManager.surfaceTemperature = r })
            thermalManager.typedCall("core_temperature", [], function(r) { thermalManager.coreTemperature = r })
            thermalManager.typedCall("battery_temperature", [], function(r) { thermalManager.batteryTemperature = r })
            thermalManager.typedCall("sensor_temperature", [{ "type": "s", "value": "system" }], function(r) { thermalManager.systemTemperature = r })
        }
    }
}
