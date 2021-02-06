/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import org.nemomobile.lipstick 0.1
import Sailfish.Silica 1.0
import com.jolla.lipstick 0.1

EventsViewList {
    id: eventFeedWindow
    objectName: "EventsView_window"

    signal shown
    signal peeked
    signal screenLocked
    signal screenBlanked

    onShown: fadeInAnimation.restart()

    onPeeked: {
        fadeInAnimation.stop()
        opacity = 1
    }

    onScreenLocked: fadeInAnimation.stop()
    statusBarHeight: Lipstick.compositor.homeLayer.statusBar.baseY + Lipstick.compositor.homeLayer.statusBar.height

    Connections {
        target: Lipstick.compositor.eventsLayer
        onDeactivated: eventFeedWindow.contentY = eventFeedWindow.originY - eventFeedWindow.topMargin
    }

    FadeAnimation {
        id: fadeInAnimation
        target: eventFeedWindow
        duration: 200
        from: 0
        to: 1
        running: false
    }
}
