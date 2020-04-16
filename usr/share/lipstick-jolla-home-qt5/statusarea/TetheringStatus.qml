/****************************************************************************
**
** Copyright (c) 2013 - 2019 Jolla Ltd.
** Copyright (c) 2019 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************/

import QtQml 2.2
import MeeGo.Connman 0.2

QtObject {
    id: tethering

    readonly property string path: "system_settings/connectivity/tethering/wlan_hotspot_switch"
    readonly property bool enabled: _wlanNetworkTechnology.tethering
    readonly property alias connected: tethering.enabled

    readonly property var _wlanNetworkTechnology: NetworkTechnology {
        path: _networkManager.WifiTechnology
    }

    readonly property var _networkManager: NetworkManager {}
}
