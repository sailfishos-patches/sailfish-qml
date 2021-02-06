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

    property Item wallpaperWrapper
    readonly property Item wallpaper: wallpaperWrapper && wallpaperWrapper.mapped ? wallpaperWrapper.window : null
    readonly property var backgroundProperties: {
        var properties = windowProperty("BACKGROUND_ATTRIBUTES")
        return properties !== undefined
                ? JSON.parse(properties)
                : undefined
    }

    hasCover: typeof coverWindowId.value !== "undefined"
    hasChildWindows: windowProperty("HAS_CHILD_WINDOWS", false)
    windowOpacity: windowProperty("WINDOW_OPACITY", 1.0)
    backgroundRect: windowProperty("BACKGROUND_RECT", Qt.rect(0, 0, width, height))

    Behavior on opacity {
        enabled: fadeEnabled
        FadeAnimator { duration: 600 }
    }

    function windowProperty(key, defaultValue) {
        return window
                && window.surface
                && window.surface.windowProperties[key] !== undefined
            ? window.surface.windowProperties[key]
            : defaultValue
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
