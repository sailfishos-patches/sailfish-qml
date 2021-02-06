/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import QtQuick.Window 2.1 as QtQuick
import com.jolla.lipstick 0.1

Item {
    id: wallpaperWrapper

    property Item window
    property Item wallpaperFor
    property int windowType: WindowType.Wallpaper
    property bool mapped: true
    readonly property Item windowWrapper: (wallpaperFor && wallpaperFor.userData) || null

    function setAsWallpaper() {
        if (windowWrapper) {
            windowWrapper.wallpaperWrapper = wallpaperWrapper
        }
    }

    function clearAsWallpaper() {
        if (windowWrapper && windowWrapper.wallpaperWrapper === wallpaperWrapper) {
            windowWrapper.wallpaperWrapper = null
        }
    }

    onWindowWrapperChanged: {
        setAsWallpaper()
    }

    Connections {
        target: (wallpaperWrapper.window && wallpaperWrapper.window.surface) || null
        onMapped: wallpaperWrapper.mapped = true
        onUnmapped: wallpaperWrapper.mapped = false
    }
}
