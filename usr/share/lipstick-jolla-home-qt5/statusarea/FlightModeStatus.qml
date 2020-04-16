/****************************************************************************
**
** Copyright (c) 2013-2019 Jolla Ltd.
** Copyright (c) 2019 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************/

import QtQml 2.2
import MeeGo.Connman 0.2

NetworkManager {
    id: flightMode

    readonly property string path: "system_settings/connectivity/flight/enable_switch"
    readonly property bool enabled: flightMode.offlineMode
    readonly property alias connected: flightMode.enabled
}
