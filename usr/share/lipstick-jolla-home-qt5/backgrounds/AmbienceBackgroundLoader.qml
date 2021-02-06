/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1

SynchronizedWallpaperLoader {
    readonly property Item applicationWallpaperItem: Lipstick.compositor.wallpaper.applicationWallpaperItem
    property var applicationProperties

    function properties(item, ambience) {
        var properties = {
            "sourceItem": item,
            "colorScheme": ambience.colorScheme,
            "highlightColor": ambience.highlightColor
        }

        for (var property in applicationProperties) {
            properties[property] = applicationProperties[property]
        }

        return properties
    }

    sourceItem: applicationWallpaperItem
    overrideAnimating: animation.running

    onApplicationWallpaperItemChanged: reload()
    onApplicationPropertiesChanged: reload()
    onAnimate: {
        if (!wallpaperAnimating) {
            if (item) {
                item.opacity = 0

                animation.target = item
                animation.from = 0
                animation.to = 1
                animation.restart()
            } else if (replacedItem) {
                animation.target = replacedItem
                animation.from = 1
                animation.to = 0
                animation.restart()
            }
        }
    }

    FadeAnimator {
        id: animation

        duration: 800
        running: false
    }
}
