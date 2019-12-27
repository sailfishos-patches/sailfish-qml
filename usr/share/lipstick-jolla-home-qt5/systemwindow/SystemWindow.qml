/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Vesa Halttunen <vesa.halttunen@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1

FocusScope {
    id: systemWindow
    property bool transpose: Lipstick.compositor.topmostWindowAngle % 180 != 0
    property real contentHeight: height

    property bool shouldBeVisible
    property real _windowOpacity: shouldBeVisible ? 1.0 : 0.0

    property alias fadeEnabled: fadeBehavior.enabled
    readonly property alias fadeRunning: fadeAnimation.running
    readonly property bool windowVisible: fadeAnimation.running || _windowOpacity > 0.0

    property bool _backgroundVisible: true
    property rect _backgroundRect: {
        switch (Lipstick.compositor.topmostWindowAngle) {
        case 90:
        case -270:
            return Qt.rect(height - contentHeight, 0, contentHeight, width)
        case 180:
        case -180:
            return Qt.rect(0, height - contentHeight, width, contentHeight)
        case 270:
        case -90:
            return Qt.rect(0, 0, contentHeight, width)
        case 0:
        case 360:
        default:
            return Qt.rect(0, 0, width, contentHeight)
        }
    }

    signal hidden()

    width: transpose ? Lipstick.compositor.height : Lipstick.compositor.width
    height: transpose ? Lipstick.compositor.width : Lipstick.compositor.height

    transform: Rotation {
        origin.x: (Lipstick.compositor.topmostWindowAngle == 90 ? height : width) / 2
        origin.y: (Lipstick.compositor.topmostWindowAngle < 270 ? height : width) / 2
        angle: Lipstick.compositor.topmostWindowAngle
    }

    Behavior on _windowOpacity {
        id: fadeBehavior
        enabled: systemWindow.windowVisible
        SequentialAnimation {
            id: fadeAnimation

            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
            ScriptAction { script: if (!systemWindow.shouldBeVisible) { systemWindow.hidden() } }
        }
    }
}
