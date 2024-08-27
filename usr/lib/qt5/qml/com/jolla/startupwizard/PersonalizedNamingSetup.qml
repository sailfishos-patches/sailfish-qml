/*
 * Copyright (c) 2015 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Connman 0.2
import org.nemomobile.systemsettings 1.0

Item {
    id: root

    function personalizeBroadcastNames() {
        wifiTechnology.tetheringId = deviceInfo.prettyName
    }

    DeviceInfo {
        id: deviceInfo
    }

    NetworkManagerFactory {
        id: networkManager
    }

    Connections {
        target: networkManager.instance
        onTechnologiesChanged: wifiTechnology.path = networkManager.instance.technologyPathForType("wifi")
    }

    NetworkTechnology {
        id: wifiTechnology
        path: networkManager.instance.technologyPathForType("wifi")
    }
}
