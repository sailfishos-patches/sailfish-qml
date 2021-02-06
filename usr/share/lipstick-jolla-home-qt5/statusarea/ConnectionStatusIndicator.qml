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
import MeeGo.Connman 0.2
import org.nemomobile.lipstick 0.1
import com.jolla.lipstick 0.1

Item {
    id: connectionStatusIndicator
    property bool updatesEnabled: true

    width: primaryIcon.width
    height: primaryIcon.height

    visible: primaryIcon.status == Image.Ready || secondaryIcon.status == Image.Ready

    TetheringStatus {
        id: tethering
    }

    Timer {
        id: signalStrength

        property int iconLevel
        readonly property string iconId: ConnectionManager.connectingWifi ?
            ("icon-status-wlan-connecting-" + iconLevel) : (actualLevel >= 0) ?
            ("icon-status-wlan-" + actualLevel) : ""
        readonly property int actualLevel: {
            var wifi = ConnectionManager.connectedWifi
            if (wifi) {
                var strength = wifi.strength
                return (strength >= 59) ? 4 :
                       (strength >= 55) ? 3 :
                       (strength >= 50) ? 2 :
                       (strength >= 40) ? 1 : 0
            }
            return -1
        }

        interval: 250
        running: connectionStatusIndicator.parent.visible && ConnectionManager.connectingWifi
        onRunningChanged: if (running) iconLevel = 0
        onTriggered: iconLevel = (iconLevel + 1) % 5
        repeat: true
    }

    property string _wlanIconId: {
        // WLAN off
        if (!wlanStatus.enabled)
            return ""

        // WLAN tethering
        if (tethering.enabled)
            return ""

        // WLAN connected or connecting
        if (ConnectionManager.connectedWifi || ConnectionManager.connectingWifi)
            return signalStrength.iconId

        // WLAN not connected, network available
        if (ConnectionManager.servicesList("wifi").length > 0)
            return "icon-status-wlan-available"

        // WLAN no signal
        return "icon-status-wlan-no-signal"
    }

    property string _cellularIconId: {
        // Cellular off
        if (!mobileDataStatus.enabled)
            return ""

        // Cellular connected
        if (mobileDataStatus.connected) {
            if (mobileNetworkMonitor.uploading && mobileNetworkMonitor.downloading) {
                // Mobile data, bi-directional traffic
                return "icon-status-data-traffic"
            } else if (mobileNetworkMonitor.uploading) {
                // Mobile data, uploading data
                return "icon-status-data-upload"
            } else if (mobileNetworkMonitor.downloading) {
                // Mobile data, downloading data
                return "icon-status-data-download"
            } else {
                // Mobile data enabled, inactive
                return "icon-status-data-no-traffic"
            }
        }

        return ""
    }

    Icon {
        id: primaryIcon

        opacity: blinkIconTimer.primaryIconVisible ? 1 : 0
        source: {
            if (wlanStatus.connected && _wlanIconId !== "")
                return "image://theme/" + _wlanIconId + iconSuffix
            else if (_cellularIconId !== "")
                return "image://theme/" + _cellularIconId + mobileDataIconSuffix
            else if (_wlanIconId !== "")
                return "image://theme/" + _wlanIconId + iconSuffix
            else
                return ""
        }

        Behavior on opacity { FadeAnimation { } }
        anchors.bottom: parent.bottom
    }

    Icon {
        id: secondaryIcon
        source: {
            if (wlanStatus.connected && _cellularIconId !== "")
                return "image://theme/" + _cellularIconId + mobileDataIconSuffix
            else if (mobileDataStatus.connected && _wlanIconId !== "")
                return "image://theme/" + _wlanIconId + iconSuffix
            else
                return ""
        }

        opacity: 1 - primaryIcon.opacity
        anchors.bottom: parent.bottom
    }

    Icon {
        id: tetheringOverlay
        source: "image://theme/icon-status-data-share" + mobileDataIconSuffix
        visible: tethering.enabled
        anchors.bottom: parent.bottom
    }

    Timer {
        id: blinkIconTimer

        property bool primaryIconVisible: true

        interval: 1000
        repeat: true
        running: wlanStatus.connected &&
                 _wlanIconId !== "" && _cellularIconId !== "" &&
                 _cellularIconId !== "icon-status-data-no-traffic"
        onRunningChanged: {
            if (!running)
                primaryIconVisible = true
        }

        onTriggered: primaryIconVisible = !primaryIconVisible
    }

    WlanStatus {
        id: wlanStatus
    }

    MobileDataStatus {
        id: mobileDataStatus
    }

    NetworkTrafficMonitor {
        id: mobileNetworkMonitor

        accuracy: 10 //update threshold in kilobytes
        interval: 2 // poll in seconds
        polling: ConnectionManager.available
                    && mobileDataStatus.connected
                    && connectionStatusIndicator.updatesEnabled
        servicePrefix: "/net/connman/service/cellular_"
    }
}
