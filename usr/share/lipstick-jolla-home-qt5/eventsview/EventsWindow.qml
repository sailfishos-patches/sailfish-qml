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
        target: Lipstick.compositor.homeLayer.dimmer
        property: "dimmed"
        value: true
    }

    initialPage: Component { Page {
        id: desktop

        allowedOrientations: Orientation.All

        property bool eventsViewVisible: Lipstick.compositor.eventsLayer.visible
        onEventsViewVisibleChanged: Desktop.eventsViewVisible = eventsViewVisible

        property bool eventsViewActive: (Lipstick.compositor.homeActive || Lipstick.compositor.homePeeking) && Lipstick.compositor.eventsLayer.isCurrentItem
        onEventsViewActiveChanged: eventsViewActive ? eventsViewInactiveTimer.stop() : eventsViewInactiveTimer.start()

        property bool screenLocked: Lipstick.compositor.notificationOverviewLayer.lockScreenLocked
        onScreenLockedChanged: {
            if (screenLocked) {
                screenBlankTimer.restart()
                eventsView.screenLocked()
            } else {
                screenBlankTimer.stop()
                if (Lipstick.compositor.lockScreenLayer.exposed && !Lipstick.compositor.lockScreenLayer.peekedAt) {
                    eventsView.shown(Lipstick.compositor.lockScreenLayer.notificationAnimation === "immediate")
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
            anchors.fill: desktop
        }

        Timer {
            id: eventsViewInactiveTimer
            interval: 5 * 60 * 1000 // 5 mins
            onTriggered: eventsView.deactivated()
        }

        Timer {
            id: screenBlankTimer
            interval: 1000 // 1 second
            onTriggered: eventsView.screenBlanked()
        }

        Binding {
            target: Lipstick.compositor.eventsLayer
            property: "contentY"
            value: eventsView.contentY
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
