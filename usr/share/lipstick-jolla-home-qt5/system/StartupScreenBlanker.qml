/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.1
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1

Rectangle {
    id: startupWizardBlanker
    anchors.fill: parent
    parent: Lipstick.compositor.contentItem

    color: "black"
    opacity: 1
    visible: opacity > 0

    signal hidden
    onVisibleChanged: {
        if (!visible && opacity == 0) {
            hidden()
        }
    }

    Behavior on opacity {
        SequentialAnimation {
            // fadeout gets triggered at the same time as window animation
            // is started -- wait a bit for the window fade-in to finish
            PauseAnimation { duration: 400 }
            FadeAnimation { }
        }
    }

    TouchBlocker {
        anchors.fill: parent
    }

    BusyIndicator {
        id: busyIndicator

        size: BusyIndicatorSize.Large
        y: Math.round(parent.height/4)
        anchors.horizontalCenter: parent.horizontalCenter
    }

    function hide() {
        opacity = 0
    }

    Connections {
        target: Lipstick.compositor.appLayer
        onWindowChanged: hide()
    }
    Connections {
        target: Lipstick.compositor.alarmLayer
        onWindowChanged: hide()
    }

    Component.onCompleted: {
        busyIndicator.running = true
    }
}
