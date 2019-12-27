/****************************************************************************
**
** Copyright (c) 2018 - 2019 Jolla Ltd.
** Copyright (c) 2019 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************/

import QtQuick 2.2
import MeeGo.Connman 0.2
import org.nemomobile.systemsettings 1.0

QtObject {
    id: vpn

    readonly property string path: "system_settings/connectivity/vpn/enable_switch"
    readonly property bool enabled: SettingsVpnModel.bestState === VpnConnection.Ready || SettingsVpnModel.bestState === VpnConnection.Configuration
    readonly property alias connected: vpn.enabled
}
