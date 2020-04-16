/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Telephony 1.0
import Sailfish.Lipstick 1.0
import Csd 1.0
import org.nemomobile.time 1.0
import org.nemomobile.dbus 2.0
import org.nemomobile.systemsettings 1.0
import com.jolla.settings.system 1.0
import MeeGo.Connman 0.2
import Nemo.Mce 1.0

Page {
    id: page

    property alias _simManager: simManager

    SilicaFlickable {
        anchors.fill: parent

        contentHeight: column.height + column.y

        Column {
            id: column
            y: Theme.paddingMedium
            width: parent.width
            spacing: Theme.paddingSmall

            CompactSection {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                //% "Power"
                title: qsTrId("csd-he-power")

                Row {
                    spacing: Theme.paddingMedium
                    Label { text: Math.round(battery.current).toFixed() + "mA" }
                    Label { text: mceBatteryState.valueName() }
                    Label { text: mceBatteryLevel.percent + "%" }
                }
                Row {
                    spacing: Theme.paddingMedium
                    //% "Uptime: %1m"
                    Label { text: qsTrId("csd-la-uptime").arg((mce.uptime/1000/60).toFixed(0)) }
                    //% "Suspend: %1m (%2%)"
                    Label { text: qsTrId("csd-la-suspend").arg((mce.suspend/1000/60).toFixed(0)).arg((100*mce.suspend/mce.uptime).toFixed(0)) }
                }

                MceBatteryLevel {
                    id: mceBatteryLevel
                }
                MceBatteryState {
                    id: mceBatteryState

                    function valueName() {
                        if (value === MceBatteryState.Full)
                            return "Full"
                        if (value === MceBatteryState.Charging)
                            return "Charging"
                        if (value === MceBatteryState.Discharging)
                            return "Discharging"
                        if (value === MceBatteryState.NotCharging)
                            return "NotCharging"
                        return "Unknown"
                    }
                }
            }

            CompactSection {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                //% "Display"
                title: qsTrId("csd-he-display")
                Row {
                    spacing: Theme.paddingLarge
                    Label {
                        //% "Brightness: %1%"
                        text: qsTrId("csd-la-brightness").arg(displaySettings.brightness)
                    }
                    CheckLabel {
                        checked: displaySettings.autoBrightnessEnabled
                        //% "Auto-brightness"
                        text: qsTrId("csd-la-auto-brightness")
                    }
                }
                Row {
                    spacing: Theme.paddingLarge
                    CheckLabel {
                        checked: displaySettings.ambientLightSensorEnabled
                        //: Ambient light sensor. Try to keep this short to save space
                        //% "ALS"
                        text: qsTrId("csd-la-ambient-light-sensor")
                    }
                    Label {
                        text: "Dim %1s, Blank %2s".arg(displaySettings.dimTimeout).arg(displaySettings.blankTimeout)
                    }
                }
            }

            CompactSection {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                //% "WLAN"
                title: qsTrId("csd-he-wlan")
                Row {
                    id: wlanRow
                    spacing: Theme.paddingMedium
                    CheckLabel {
                        checked: wlanNetworkTechnology.powered
                        //% "Enabled"
                        text: qsTrId("csd-la-enabled")
                    }
                    CheckLabel {
                        checked: wlanNetworkTechnology.connected
                        //% "Connected"
                        text: qsTrId("csd-la-connected")
                    }
                    Row {
                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            source: {
                                var path = function(name) {
                                    return "image://theme/icon-status-" + name
                                }

                                // WLAN off
                                if (!wlanNetworkTechnology.powered)
                                    return "";

                                // WLAN connected
                                if (wlanNetworkTechnology.connected) {
                                    if (networkManager.defaultRoute.type !== "wifi" && networkManager.defaultRoute.type !== "")
                                        return path("wlan-0")

                                    if (networkManager.defaultRoute.strength >= 59) {
                                        return path("wlan-4")
                                    } else if (networkManager.defaultRoute.strength >= 55) {
                                        return path("wlan-3")
                                    } else if (networkManager.defaultRoute.strength >= 50) {
                                        return path("wlan-2")
                                    } else if (networkManager.defaultRoute.strength >= 40) {
                                        return path("wlan-1")
                                    } else {
                                        return path("wlan-0")
                                    }
                                }

                                // WLAN not connected, network available
                                if (networkManager.servicesList("wifi").length > 0)
                                    return path("wlan-available")

                                // WLAN no signal
                                return path("wlan-no-signal")
                            }
                        }
                        Item { width: Theme.paddingSmall; height: 1 }
                        Label {
                            visible: wlanNetworkTechnology.connected
                            text: networkManager.defaultRoute.strength
                        }
                    }
                }
            }

            CompactSection {
                //% "Cellular"
                title: qsTrId("csd-he-cellular")
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x

                Repeater {
                    model: simManager.availableModems

                    CellularStatus {
                        modemPath: modelData
                        simManager: page._simManager
                    }
                }

                Row {
                    spacing: Theme.paddingLarge
                    CheckLabel {
                        checked: wlanNetworkTechnology.tethering
                        //% "Tethering"
                        text: qsTrId("csd-la-tethering")
                    }
                }
            }

            CompactSection {
                //% "Bluetooth"
                title: qsTrId("csd-he-bluetooth")
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                Row {
                    spacing: Theme.paddingMedium
                    CheckLabel {
                        checked: bluetoothStatus.enabled
                        //% "Enabled"
                        text: qsTrId("csd-la-enabled")
                    }
                    CheckLabel {
                        checked: bluetoothStatus.connected
                        //% "Connected"
                        text: qsTrId("csd-la-connected")
                    }
                }
            }

            CompactSection {
                //% "Radios"
                title: qsTrId("csd-he-radios")
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                visible: nfcLoader.active && nfcLoader.status === Loader.Ready
                Row {
                    spacing: Theme.paddingMedium
                    Loader {
                        id: nfcLoader
                        active: Features.supported("NFC");
                        source: "NfcStatus.qml"
                    }
                    /* TODO: find a way to observe without affecting state. Even opening the device causes issues.
                    Loader {
                        active: Features.supported("FmRadio");
                        sourceComponent: CheckLabel {
                            //% "FM tx"
                            text: qsTrId("csd-la-fmtx")
                        }
                    }
                    */
                }
            }
/*
            CompactSection {
                //% "Misc"
                title: qsTrId("csd-he-misc")
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x

                Label {
                    //% "Flashlight: %1"
                    text: qsTrId("csd-la-flashlight").arg()
                }
            }
*/
            CompactSection {
                //% "GPS"
                title: qsTrId("csd-he-gps")
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                Row {
                    id: gpsRow
                    spacing: Theme.paddingMedium
                    Loader {
                        active: Features.supported("GPS");
                        sourceComponent: CheckLabel {
                            checked: locationSettings.locationEnabled && locationSettings.gpsAvailable && locationSettings.gpsEnabled && !locationSettings.gpsFlightMode
                            text: "GPS"
                        }
                    }
                    CheckLabel {
                        visible: locationSettings.hereAvailable
                        checked: locationSettings.hereState == locationSettings.OnlineAGpsEnabled
                        text: "HERE"
                    }
                    CheckLabel {
                        visible: locationSettings.mlsAvailable
                        checked: locationSettings.mlsEnabled
                        text: "cellId"
                    }
                }
            }

            CompactSection {
                //% "Audio"
                title: qsTrId("csd-he-audio")
                x: Theme.horizontalPageMargin
                width: parent.width - x*2

                Label {
                    //% "Audio sources: %1"
                    text: qsTrId("csd-la-audio_souces").arg(audioSources.count)
                }

                Repeater {
                    id: audioSources
                    model: PulseAudio {}
                    delegate: Column {
                        //% "Name: %1"
                        Label { text: qsTrId("csd-la-audio_name").arg(applicationName || mediaName) }
                        Row {
                            spacing: Theme.paddingMedium
                            CheckLabel {
                                //% "Corked"
                                text: qsTrId("csd-la-audio_corked")
                                checked: corked
                            }
                            CheckLabel {
                                //% "Muted"
                                text: qsTrId("csd-la-audio_muted")
                                checked: muted
                            }
                            //% "Volume: %1"
                            Label { text: qsTrId("csd-la-audio_volume").arg(volumeInfo) }
                        }
                    }
                }
            }

            SectionHeader {
                //% "CPU"
                text: qsTrId("csd-he-cpu")
                height: implicitHeight - Theme.paddingSmall
            }
            Item {
                id: cpu
                x: Theme.horizontalPageMargin
                width: parent.width - x*2
                height: loadAvg.height
                Column {
                    id: processColumn
                    width: 2*cpu.width/3
                    Repeater {
                        model: Processes { id: processesModel; limit: 4 }
                        delegate: Row {
                            spacing: Theme.paddingSmall
                            Label { id: pc; text: percentCpu.toFixed(1)+"%" }
                            Label {
                                width: Math.min(implicitWidth, 2*cpu.width/3 - pc.width - Theme.paddingSmall)
                                text: name
                                truncationMode: TruncationMode.Fade
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
                BusyIndicator {
                    anchors {
                        horizontalCenter: processColumn.horizontalCenter
                        verticalCenter: loadAvg.verticalCenter
                    }
                    running: processesModel.count === 0
                }

                Rectangle {
                    x: 2*cpu.width/3 + Theme.paddingMedium
                    height: cpu.height
                    width: Theme.paddingSmall/2
                    color: Theme.highlightDimmerColor
                }
                Column {
                    id: loadAvg
                    anchors.right: parent.right
                    width: cpu.width/3 - Theme.paddingLarge
                    Label {
                        width: parent.width
                        truncationMode: TruncationMode.Fade
                        //% "Load avg."
                        text: qsTrId("csd-la-load_average")
                        horizontalAlignment: Text.AlignRight
                    }
                    Label { text: uptime.loadAverage1.toFixed(2); anchors.right: parent.right }
                    Label { text: uptime.loadAverage5.toFixed(2); anchors.right: parent.right }
                    Label { text: uptime.loadAverage15.toFixed(2); anchors.right: parent.right }
                }
            }
        }
    }

    Uptime { id: uptime }
    Mce { id: mce }
    DisplaySettings { id: displaySettings }

    NetworkManager {
        id: networkManager

        property bool technologyPathsValid: wlanNetworkTechnology.path !== "" && mobileNetworkTechnology.path !== ""

        function updateTechnologies() {
            if (available && technologiesEnabled) {
                wlanNetworkTechnology.path = networkManager.technologyPathForType("wifi")
                mobileNetworkTechnology.path = networkManager.technologyPathForType("cellular")
            }
        }

        onAvailableChanged: updateTechnologies()
        onTechnologiesEnabledChanged: updateTechnologies()
        onTechnologiesChanged: updateTechnologies()
    }

    NetworkTechnology {
        id: wlanNetworkTechnology
    }

    NetworkTechnology {
        id: mobileNetworkTechnology
        property bool uploading: false
        property bool downloading: false
    }

    BluetoothStatus {
        id: bluetoothStatus
    }

    SimManager {
        id: simManager
    }

    LocationSettings { id: locationSettings }

    Battery {
        id: battery
        property double current: NaN
    }

    Timer {
        interval: 1000
        repeat: true
        running: page.status === PageStatus.Active
        triggeredOnStart: true

        onTriggered: battery.current = battery.currentNow() * 1e-3
    }
}
