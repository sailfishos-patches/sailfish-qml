/****************************************************************************
**
** Copyright (c) 2013 - 2019 Jolla Ltd.
** Copyright (c) 2019 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import Sailfish.Telephony 1.0
import Sailfish.Settings.Networking 1.0
import com.jolla.lipstick 0.1
import org.nemomobile.devicelock 1.0
import org.nemomobile.lipstick 0.1
import org.nemomobile.time 1.0
import "../lockscreen"
import "../main"
import "../backgrounds"

ContrastBackground {
    id: statusArea
    property bool updatesEnabled: true
    property bool recentlyOnDisplay: true
    property bool lockscreenMode
    property string iconSuffix: lipstickSettings.lowPowerMode ? ('?' + Theme.highlightColor) : ''
    property string mobileDataIconSuffix: '?' + (lipstickSettings.lowPowerMode ? Theme.highlightColor : mobileDataIconColor)
    property alias mobileDataIconColor: cellularStatusLoader.mobileDataColor
    property color color: lipstickSettings.lowPowerMode ? Theme.highlightColor : Theme.primaryColor

    onUpdatesEnabledChanged: if (updatesEnabled) recentlyOnDisplay = updatesEnabled
    height: batteryStatusIndicator.totalHeight
    width: parent.width

    Timer {
        interval: 3000
        running: !statusArea.updatesEnabled
        onTriggered: statusArea.recentlyOnDisplay = statusArea.updatesEnabled
    }

    Item {
        id: iconBar
        width: parent.width
        height: batteryStatusIndicator.height

        // Left side status indicators
        Row {
            id: leftIndicators
            height: batteryStatusIndicator.height
            spacing: Theme.paddingSmall
            BatteryStatusIndicator {
                id: batteryStatusIndicator
                color: statusArea.color
                usbPreparingMode: usbModeSelector.preparingMode != ""
                iconSuffix: statusArea.iconSuffix
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

            Loader {
                active: Desktop.showDualSim
                visible: active
                sourceComponent: floatingIndicators
            }
        }

        // These indicators could be on either side, depending upon dual sim
        Component {
            id: floatingIndicators
            Row {
                spacing: Theme.paddingSmall
                BluetoothStatusIndicator {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: opacity > 0.0
                }
                LocationStatusIndicator {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: opacity > 0.0
                    recentlyOnDisplay: statusArea.recentlyOnDisplay
                }
            }
        }

        Item {
            id: centralArea
            anchors {
                top: iconBar.top
                bottom: iconBar.bottom
                left: leftIndicators.right
                leftMargin: Theme.paddingMedium
                right: rightIndicators.left
                rightMargin: Theme.paddingMedium
            }
            Loader {
                // If possible position this item centrally within the iconBar
                x: Math.max((iconBar.width - width)/2 - parent.x, 0)
                y: (parent.height - height)/2
                sourceComponent: lockscreenMode ? lockIcon : timeText
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

        // Right side status indicators
        Row {
            id: rightIndicators
            height: parent.height
            spacing: Theme.paddingSmall
            anchors {
                right: parent.right
                rightMargin: Theme.paddingMedium
            }
            VpnStatusIndicator {
                id: vpnStatusIndicator
                anchors.verticalCenter: parent.verticalCenter
            }
            Loader {
                active: !Desktop.showDualSim
                visible: active
                sourceComponent: floatingIndicators
            }
            ConnectionStatusIndicator {
                id: connStatusIndicator
                anchors.verticalCenter: parent.verticalCenter
                updatesEnabled: statusArea.recentlyOnDisplay
            }
            Item {
                width: flightModeStatusIndicator.offline ? flightModeStatusIndicator.width : cellularStatusLoader.width
                height: iconBar.height
                visible: Desktop.simManager.enabledModems.length > 0 || flightModeStatusIndicator.offline

                FlightModeStatusIndicator {
                    id: flightModeStatusIndicator
                    anchors.right: parent.right
                }

                Loader {
                    id: cellularStatusLoader
                    height: parent.height
                    active: Desktop.simManager.availableModemCount > 0
                    readonly property color mobileDataColor: item ? item.mobileDataColor : statusArea.color
                    sourceComponent: Row {
                        property alias mobileDataColor: cellularNetworkTypeStatusIndicator.color
                        height: parent.height
                        opacity: 1.0 - flightModeStatusIndicator.opacity

                        CellularNetworkTypeStatusIndicator {
                            id: cellularNetworkTypeStatusIndicator
                            anchors.verticalCenter: parent.verticalCenter
                            color: {
                                var repeaterItem = Desktop.simManager.indexOfModem(Desktop.simManager.defaultDataModem) === 1 && networkStatusRepeater.count > 1
                                        ? networkStatusRepeater.itemAt(1)
                                        : networkStatusRepeater.itemAt(0)
                                return !!repeaterItem ? repeaterItem.iconColor : statusArea.color
                            }
                        }

                        Repeater {
                            id: networkStatusRepeater

                            model: Desktop.simManager.enabledModems

                            MobileNetworkStatusIndicator {
                                readonly property color iconColor: _highlight ? Theme.highlightColor : statusArea.color
                                readonly property bool _highlight: Telephony.promptForVoiceSim
                                                                   || (Desktop.showDualSim && Desktop.simManager.activeModem !== modemPath)

                                visible: Desktop.showDualSim || Desktop.simManager.activeModem === modemPath
                                modemPath: modelData
                                simManager: Desktop.simManager

                                showMaximumStrength: fakeOperator !== ""
                                showRoamingStatus: !Desktop.showDualSim
                                iconSuffix: _highlight ? ('?' + Theme.highlightColor) : statusArea.iconSuffix
                            }
                        }
                    }
                }
            }
        }
    }
}
