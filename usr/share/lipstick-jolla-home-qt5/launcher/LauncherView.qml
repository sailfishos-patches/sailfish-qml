/*
 * Copyright (c) 2015 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import org.nemomobile.lipstick 0.1
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import com.jolla.lipstick 0.1
import "../main"
import "../backgrounds"

ApplicationWindow {
    id: launcherWindow

    cover: undefined

//    enabled: !Lipstick.compositor.deviceIsLocked

    allowedOrientations: Lipstick.compositor.topmostWindowOrientation

    children: MenuBackground {
        z: -1

        anchors.fill: parent
    }

    initialPage: Component { Page {
        id: page

        allowedOrientations: Orientation.All
        layer.enabled: orientationTransitionRunning

        Launcher {
            // We don't want the pager to resize due to keyboard being shown.
            height: Math.ceil(page.height + pageStack.panelSize)
            width: parent.width
        }

        orientationTransitions: OrientationTransition {
            page: page
            applicationWindow: launcherWindow
        }
    } }
}
