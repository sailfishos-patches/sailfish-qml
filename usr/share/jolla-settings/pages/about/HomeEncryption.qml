/*
 * Copyright (c) 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Encryption 1.0
import Sailfish.Silica 1.0

DetailItem {
    //% "Home Encryption"
    label: qsTrId("settings_about-la-home_encryption")
    //: Enabled %1 is type and %2 is version
    //% "Enabled (%1 %2)"
    value: qsTrId("settings_about-la-home_encryption_enabled").arg(homeInfo.type || "LUKS").arg(homeInfo.version)

    HomeInfo {
        id: homeInfo
    }
}
