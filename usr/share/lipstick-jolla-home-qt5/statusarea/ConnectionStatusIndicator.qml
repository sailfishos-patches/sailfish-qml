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

    property string _wlanIconId: {
        // WLAN off
        if (!wlanStatus.enabled)
            return "";

        // WLAN tethering
        if (tethering.enabled)
            return "";

        // WLAN connected
        var wifi = ConnectionManager.connectedWifi
        if (wifi) {
            if (wifi.strength >= 59) {
                return "icon-status-wlan-4"
            } else if (wifi.strength >= 55) {
                return "icon-status-wlan-3"
            } else if (wifi.strength >= 50) {
                return "icon-status-wlan-2"
            } else if (wifi.strength >= 40) {
                return "icon-status-wlan-1"
            } else {
                return "icon-status-wlan-0"
            }
        }

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

    Image {
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

    Image {
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

    Image {
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
