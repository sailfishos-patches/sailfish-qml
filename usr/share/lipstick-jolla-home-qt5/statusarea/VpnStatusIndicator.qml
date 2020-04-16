/****************************************************************************
**
** Copyright (c) 2016 - 2019 Jolla Ltd.
** Copyright (c) 2019 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import MeeGo.Connman 0.2
import org.nemomobile.systemsettings 1.0

Item {
    id: vpnStatusIndicator

    width: icon.width
    height: icon.height
    visible: icon.status == Image.Ready

    VpnStatus {
        id: vpnStatus
    }

    Image {
        id: icon

        source: {
            if (vpnStatus.connected)
                return "image://theme/icon-status-vpn"
            /* No icon available for failure mode...
            else if (SettingsVpnModel.bestState == VpnConnection.Failure)
                return "image://theme/icon-status-vpn-failure"
            */
            else
                return ""
        }

        opacity: blinkTimer.iconVisible ? 1 : 0
        Behavior on opacity { FadeAnimation { } }
    }

    Timer {
        id: blinkTimer

        property bool iconVisible: true

        interval: 1000
        repeat: true
        running: SettingsVpnModel.bestState == VpnConnection.Configuration && Qt.application.active
        onRunningChanged: {
            if (!running) {
                iconVisible = true
            }
        }
        onTriggered: iconVisible = !iconVisible
    }
}
