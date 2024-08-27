/****************************************************************************
**
** Copyright (c) 2013 - 2019 Jolla Ltd.
** Copyright (c) 2019 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import Sailfish.Telephony 1.0
import Sailfish.Settings.Networking 1.0
import com.jolla.lipstick 0.1
import org.nemomobile.devicelock 1.0
import org.nemomobile.lipstick 0.1
import Nemo.Time 1.0
import Nemo.Configuration 1.0
import "../lockscreen"
import "../main"
import "../backgrounds"

ContrastBackground {
    id: statusArea

    property bool updatesEnabled: true
    property bool recentlyOnDisplay: true
    property bool lockscreenMode
    property color color: Theme.primaryColor
    property int cornerPadding: {
        // assuming the roundings are simple with x and y detached the radius amount from edges.
        // for simplicity using just one padding (they are likely same anyway)
        var biggestCorner = Math.max(Screen.topLeftCorner.radius,
                                     Screen.topRightCorner.radius,
                                     Screen.bottomLeftCorner.radius,
                                     Screen.bottomRightCorner.radius)
        // 0.7 assumed being enough of the rounding to avoid
        return Math.max(biggestCorner * 0.7, Theme.paddingMedium)
    }

    onUpdatesEnabledChanged: if (updatesEnabled) recentlyOnDisplay = updatesEnabled
    height: iconBar.height
    width: parent.width

    Timer {
        interval: 3000
        running: !statusArea.updatesEnabled
        onTriggered: statusArea.recentlyOnDisplay = statusArea.updatesEnabled
    }

    Item {
        id: iconBar

        width: parent.width
        // assuming the cutout case doesn't need padding due to clock item text not drawing full height
        height: batteryStatusIndicator.height
                + (Screen.hasCutouts && Lipstick.compositor.topmostWindowOrientation === Qt.PortraitOrientation
                   ? Screen.topCutout.height : 0)

        Row {
            id: leftIndicators

            x: statusArea.cornerPadding
            height: batteryStatusIndicator.height
            spacing: Theme.paddingSmall

            BatteryStatusIndicator {
                id: batteryStatusIndicator

                color: statusArea.color
                usbPreparingMode: usbModeSelector.preparingMode != ""
            }

            ProfileStatusIndicator {
                anchors.verticalCenter: parent.verticalCenter
            }

            DoNotDisturbIndicator {
                anchors.verticalCenter: parent.verticalCenter
            }

            AlarmStatusIndicator {
                anchors.verticalCenter: parent.verticalCenter
            }

            //XXX Headset indicator
            //XXX Call forwarding indicator
        }

        Item {
            id: centralArea

            anchors {
                top: iconBar.top
                topMargin: Screen.hasCutouts && Lipstick.compositor.topmostWindowOrientation === Qt.PortraitOrientation
                           ? (Screen.topCutout.height) : 0
                bottom: iconBar.bottom
                left: leftIndicators.right
                leftMargin: Theme.paddingMedium
                right: rightIndicators.left
                rightMargin: Theme.paddingMedium
            }
            Loader {
                // If possible position this item centrally within the iconBar
                x: Math.max((iconBar.width - width)/2 - parent.x, 0)
                y: (parent.height - height) / 2
                sourceComponent: lockscreenMode ? lockIcon
                                                : displayClockOnLauncher.value ? undefined // clock already shown on the launcher header
                                                                               : timeText


                ConfigurationValue {
                    id: displayClockOnLauncher

                    key: "/desktop/sailfish/experimental/display_clock_on_launcher"
                    defaultValue: false
                }
            }
        }

        Component {
            id: timeText
            ClockItem {
                id: clock

                width: Math.min(implicitWidth, centralArea.width)
                updatesEnabled: recentlyOnDisplay
                color: statusArea.color
                font { pixelSize: Theme.fontSizeMedium; family: Theme.fontFamilyHeading }

                Connections {
                    target: Lipstick.compositor
                    onDisplayAboutToBeOn: clock.forceUpdate()
                }
            }
        }

        Component {
            id: lockIcon
            Icon {
                color: statusArea.color
                visible: Desktop.deviceLockState >= DeviceLock.Locked
                source: "image://theme/icon-s-secure"
                anchors.centerIn: parent
            }
        }

        Row {
            id: rightIndicators

            height: leftIndicators.height
            spacing: Theme.paddingSmall
            anchors {
                right: parent.right
                rightMargin: statusArea.cornerPadding
            }

            // Location status indicator positioned to leftmost on right side
            // due to JB#58226 to avoid abrupt movement of the other indicators.
            LocationStatusIndicator {
                anchors.verticalCenter: parent.verticalCenter
                visible: opacity > 0.0
                recentlyOnDisplay: statusArea.recentlyOnDisplay
            }
            VpnStatusIndicator {
                id: vpnStatusIndicator
                anchors.verticalCenter: parent.verticalCenter
            }
            BluetoothStatusIndicator {
                anchors.verticalCenter: parent.verticalCenter
                visible: opacity > 0.0
            }
            ConnectionStatusIndicator {
                id: connStatusIndicator
                anchors.verticalCenter: parent.verticalCenter
                updatesEnabled: statusArea.recentlyOnDisplay
            }
            Item {
                width: flightModeStatusIndicator.offline ? flightModeStatusIndicator.width : cellularStatusLoader.width
                height: parent.height
                visible: Desktop.simManager.enabledModems.length > 0 || flightModeStatusIndicator.offline

                FlightModeStatusIndicator {
                    id: flightModeStatusIndicator
                    anchors.right: parent.right
                }

                Loader {
                    id: cellularStatusLoader

                    height: parent.height
                    active: Desktop.simManager.availableModemCount > 0
                    sourceComponent: Row {
                        height: parent.height
                        opacity: 1.0 - flightModeStatusIndicator.opacity

                        CellularNetworkTypeStatusIndicator {
                            anchors.verticalCenter: parent.verticalCenter
                            color: {
                                var repeaterItem = (Desktop.simManager.indexOfModem(Desktop.simManager.defaultDataModem) === 1
                                                    && networkStatusRepeater.count > 1)
                                        ? networkStatusRepeater.itemAt(1)
                                        : networkStatusRepeater.itemAt(0)
                                return !!repeaterItem && repeaterItem.highlighted ? Theme.highlightColor : statusArea.color
                            }
                        }

                        Repeater {
                            id: networkStatusRepeater

                            model: Desktop.simManager.enabledModems

                            MobileNetworkStatusIndicator {
                                highlighted: Telephony.promptForVoiceSim
                                             || (Desktop.showDualSim && Desktop.simManager.activeModem !== modemPath)

                                visible: Desktop.showDualSim || Desktop.simManager.activeModem === modemPath
                                modemPath: modelData
                                simManager: Desktop.simManager

                                showMaximumStrength: fakeOperator !== ""
                                showRoamingStatus: !Desktop.showDualSim
                            }
                        }
                    }
                }
            }
        }
    }
}
