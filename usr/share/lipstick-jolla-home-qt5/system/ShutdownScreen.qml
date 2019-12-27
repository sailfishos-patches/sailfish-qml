/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Vesa Halttunen <vesa.halttunen@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import org.nemomobile.lipstick 0.1
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import "../systemwindow"

SystemWindow {
    ShutDownItem {
        id: shutdownWindow

        property bool shouldBeVisible

        opacity: shouldBeVisible ? 1 : 0
        rebooting: shutdownMode === "reboot" || shutdownMode === "upgrade"

        onOpacityAnimationFinished: if (opacity == 0) shutdownScreen.windowVisible = false

        Connections {
            target: shutdownScreen
            onWindowVisibleChanged: if (shutdownScreen.windowVisible) {
                shutdownWindow.shouldBeVisible = true
                Lipstick.compositor.onlyCurrentNotificationAllowed = true
            }
        }
    }
}
