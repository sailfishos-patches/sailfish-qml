/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.1
import org.nemomobile.lipstick 0.1
import QtQuick.Window 2.1 as QtQuick
import Sailfish.Silica 1.0

WindowWrapperBase {
    id: wrapper
    property int coverVisibility: QtQuick.Window.Hidden
    property bool fadeEnabled

    hasCover: typeof coverWindowId.value !== "undefined"
    hasChildWindows: window
                && window.surface
                && window.surface.windowProperties.HAS_CHILD_WINDOWS != undefined
                && window.surface.windowProperties.HAS_CHILD_WINDOWS

    windowOpacity: window
                && window.surface
                && window.surface.windowProperties.WINDOW_OPACITY !== undefined
            ? window.surface.windowProperties.WINDOW_OPACITY
            : 1.0
    backgroundRect: window
                && window.surface
                && window.surface.windowProperties.BACKGROUND_RECT !== undefined
            ? window.surface.windowProperties.BACKGROUND_RECT
            : Qt.rect(0, 0, width, height)

    Behavior on opacity {
        enabled: fadeEnabled
        FadeAnimator { duration: 600 }
    }
    WindowProperty {
        id: coverWindowId
        windowId: window ? window.windowId : 0
        property: "SAILFISH_COVER_WINDOW"
    }
    Connections {
        target: window && window.surface
        onMapped: wrapper.mapped = true
        onUnmapped: wrapper.mapped = false
    }

    Binding {
        target: wrapper.window && wrapper.window.surface
        property: "visibility"
        value: {
            if (wrapper.exposed) {
                return QtQuick.Window.FullScreen
            } else if (wrapper.hasCover) {
                return QtQuick.Window.Hidden
            } else {
                return wrapper.coverVisibility
            }
        }
    }
}
