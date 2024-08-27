/*
 * Copyright (c) 2021 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import Sailfish.Silica.private 1.0

Page {
    id: sdCopyPage
    backNavigation: false

    WindowGestureOverride {
        id: gestureOverride
        active: true
    }

    BusyLabel {
        running: true
        //% "Saving data to SD card"
        text: qsTrId("settings_encryption-la-saving-data")
    }
}
