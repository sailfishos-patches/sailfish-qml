/*
 * Copyright (c) 2015 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import org.nemomobile.lipstick 0.1
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import com.jolla.lipstick 0.1
import "../main"

ApplicationWindow {
    id: launcherWindow

    cover: undefined

//    enabled: !Lipstick.compositor.deviceIsLocked

    allowedOrientations: Lipstick.compositor.topmostWindowOrientation

    initialPage: Component { Page {
        id: page

        allowedOrientations: Orientation.All
        layer.enabled: orientationTransitionRunning

        Launcher {
            id: launcher

            // We don't want the pager to resize due to keyboard being shown.
            height: Math.ceil(page.height + pageStack.panelSize)
            width: parent.width
        }

        Binding {
            when: !Lipstick.compositor.multitaskingHome
            target: Lipstick.compositor.switcherLayer
            property: "contentY"
            value: {
                if (launcher.openedChildFolder) {
                    var statusBar = Lipstick.compositor.homeLayer.statusBar
                    return statusBar.baseY + statusBar.height
                } else {
                    return launcher.contentY
                }
            }
        }

        orientationTransitions: OrientationTransition {
            page: page
            applicationWindow: launcherWindow
        }
    } }
}
