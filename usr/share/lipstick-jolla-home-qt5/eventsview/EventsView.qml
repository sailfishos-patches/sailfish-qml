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

    signal shown(var immediateNotificationAnimation)
    signal peeked
    signal deactivated
    signal screenLocked
    signal screenBlanked

    onShown: {
        fadeInAnimation.restart()
        if (immediateNotificationAnimation) {
            expand(false)
        }
    }

    onPeeked: {
        fadeInAnimation.stop()
        opacity = 1
        expand(false)
    }

    onDeactivated: contentY = originY
    onScreenLocked: fadeInAnimation.stop()
    onScreenBlanked: collapse()
    animationDuration: desktop.eventsViewActive ? 200 : 0
    rightMargin: Theme.horizontalPageMargin
    statusBarHeight: Lipstick.compositor.homeLayer.statusBar.baseY + Lipstick.compositor.homeLayer.statusBar.height

    FadeAnimation {
        id: fadeInAnimation
        target: eventFeedWindow
        duration: 200
        from: 0
        to: 1
        running: false
        onRunningChanged: if (!running) { eventFeedWindow.expand(true) }
    }
}
