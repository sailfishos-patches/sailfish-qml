/*
 * Copyright (c) 2015 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1

SynchronizedWallpaperLoader {
    id: loader

    property real offset
    property real distance: width
    property bool relativeDim

    property bool dimmed: { return false }

    property real wallpaperDimOpacity: relativeDim
            ? Math.max(0, 1.0 - offset / (distance*2/3))
            : 0

    property real _dimOpacity: dimmed ? Theme.opacityHigh : 0.0
    Behavior on _dimOpacity { FadeAnimation { id: dimAnim; property: "_dimOpacity" } }

    readonly property bool dimming: relativeDim || dimAnim.running
    readonly property real percentageDimmed: Math.max(_dimOpacity, wallpaperDimOpacity)

    function properties(item, ambience) {
        return {
            "sourceItem": item,
            "homeWallpaper": Lipstick.compositor.wallpaper.homeWallpaperItem,
            "colorScheme": ambience.colorScheme,
            "highlightColor": ambience.highlightColor
        }
    }

    sourceItem: Lipstick.compositor.wallpaper.applicationWallpaperItem

    onInitializeItem: {
        item.dimmed = Qt.binding(function() { return loader.dimmed })
        item.dimming = Qt.binding(function() { return loader.dimming })
        item.percentageDimmed = Qt.binding(function() { return loader.percentageDimmed })
    }
}
