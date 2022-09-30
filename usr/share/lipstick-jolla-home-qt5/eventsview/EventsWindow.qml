/*
 * Copyright (c) 2015 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.1
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1
import com.jolla.lipstick 0.1
import "../main"

ApplicationWindow {
    id: window
    cover: undefined

    allowedOrientations: Lipstick.compositor.homeOrientation
    _defaultLabelFormat: Text.PlainText

    Binding {
        when: window._dimScreen
        target: Lipstick.compositor.wallpaper.dimmer
        property: "dimmed"
        value: true
    }

    initialPage: Component { Page {
        id: desktop

        allowedOrientations: Orientation.All

        readonly property Item lockScreenLayer: Lipstick.compositor.lockScreenLayer
        readonly property Item eventsContainer: lockScreenLayer && lockScreenLayer.eventsContainer
        property bool lockScreenEventsActive: Lipstick.compositor.lockScreenLayer.visible && eventsContainer && eventsContainer.isCurrentItem

        property bool eventsViewVisible: Lipstick.compositor.eventsLayer.visible || lockScreenEventsActive
        onEventsViewVisibleChanged: Desktop.eventsViewVisible = eventsViewVisible

        property bool eventsViewActive: Lipstick.compositor.homeActive || Lipstick.compositor.homePeeking || lockScreenEventsActive
        onEventsViewActiveChanged: eventsViewActive ? eventsViewInactiveTimer.stop() : eventsViewInactiveTimer.start()

        property bool screenLocked: Lipstick.compositor.notificationOverviewLayer.lockScreenLocked
        onScreenLockedChanged: {
            if (screenLocked) {
                screenBlankTimer.restart()
                eventsView.screenLocked()
            } else {
                screenBlankTimer.stop()
                if (Lipstick.compositor.lockScreenLayer.exposed && !Lipstick.compositor.lockScreenLayer.peekedAt) {
                    eventsView.shown()
                } else {
                    eventsView.peeked()
                }
            }
        }

        function setForceTopWindowProcessId(pid) {
            lockscreen.forceTopWindowProcessId = pid
        }

        EventsView {
            id: eventsView
            anchors {
                topMargin: -eventsView.topMargin
                fill: parent
            }
            parent: lockScreenLayer && lockScreenLayer.lockScreenEventsEnabled ? eventsContainer : desktop
        }

        Timer {
            id: eventsViewInactiveTimer
            interval: 5 * 60 * 1000 // 5 mins
            onTriggered: {
                Lipstick.compositor.eventsLayer.deactivated()
            }
        }

        Timer {
            id: screenBlankTimer
            interval: 1000 // 1 second
            onTriggered: eventsView.screenBlanked()
        }

        Binding {
            target: Lipstick.compositor.eventsLayer
            property: "contentY"
            value: eventsView.contentY + eventsView.topMargin
        }
        Binding {
            target: Lipstick.compositor.eventsLayer
            property: "menuOpen"
            value: eventsView.menuOpen
        }
        orientationTransitions: OrientationTransition {
            page: desktop
            applicationWindow: window
        }
    } }
}
