/*
 * Copyright (c) 2013 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Moblie Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import org.nemomobile.lipstick 0.1
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import "../systemwindow"

SystemWindow {
    ShutDownItem {
        id: shutdownWindow

        property bool shouldBeVisible

        function getMode() {
            if (shutdownMode === "reboot" || shutdownMode === "upgrade") {
                return ShutdownMode.Reboot
            } else if (shutdownMode === "userswitch") {
                return ShutdownMode.UserSwitch
            } else if (shutdownMode === "userswitchFailed") {
                return ShutdownMode.UserSwitchFailed
            } else {
                return ShutdownMode.Shutdown
            }
        }

        opacity: shouldBeVisible ? 1 : 0
        mode: getMode()
        uid: user

        onOpacityAnimationFinished: if (opacity == 0) shutdownScreen.windowVisible = false

        Connections {
            target: shutdownScreen
            onWindowVisibleChanged: if (shutdownScreen.windowVisible) {
                shutdownWindow.shouldBeVisible = true
                Lipstick.compositor.onlyCurrentNotificationAllowed = true
            }
            onUserSwitchFailed: shutdownWindow.mode = shutdownWindow.getMode()
        }
    }
}
