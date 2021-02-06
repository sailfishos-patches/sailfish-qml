/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private
import org.nemomobile.lipstick 0.1

Private.AnimatedLoader {
    id: loader

    property var wallpaper
    property Item sourceItem: Lipstick.compositor.wallpaper.homeWallpaperItem
    readonly property bool wallpaperAnimating: Lipstick.compositor.wallpaper.animating
    property bool overrideAnimating
    property bool delayReload

    function properties(item, ambience) {
        return { "sourceItem": item }
    }

    function reload() {
        if (overrideAnimating) {
            delayReload = true
        } else if (Lipstick.compositor) {
            delayReload = false
            load(wallpaper, "", properties(sourceItem, Lipstick.compositor.wallpaper.ambience))
        }
    }

    onSourceItemChanged: reload()

    animating: overrideAnimating || wallpaperAnimating
    asynchronous: false

    onTransitionComplete: {
        if (delayReload) {
            reload()
        }
    }

    onInitializeItem: {
        item.width = Qt.binding(function() { return loader.width })
        item.height = Qt.binding(function() { return loader.height })
        item.opacity = Qt.binding(function() {
            return loader.wallpaperAnimating && item.sourceItem ? item.sourceItem.opacity : 1
        })
    }
}
