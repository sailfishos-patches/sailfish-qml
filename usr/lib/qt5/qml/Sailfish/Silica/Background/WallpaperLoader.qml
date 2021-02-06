/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0

AnimatedLoader {
    id: loader

    property url imageUrl

    property var wallpaper: imageWallpaper

    property var properties: ({
        "imageUrl": imageUrl
    })

    readonly property alias opacityAnimationRunning: animation.running

    function _reload() {
        if (wallpaper) {
            load(wallpaper, "", properties)
        } else {
            load(undefined)
        }
    }

    function animateOpacity() {
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

    function completeOpacityAnimation() {
        animation.complete()
    }

    animating: animation.running

    implicitWidth: Math.max(
                item ? Math.min(item.width, item.height) : 0,
                replacedItem ? Math.min(replacedItem.width, replacedItem.height) : 0)
    implicitHeight: implicitWidth

    onPropertiesChanged: _reload()
    onWallpaperChanged: _reload()

    onInitializeItem: {
        item.x = Qt.binding(function() { return (loader.width - item.width) / 2 })
        item.y = Qt.binding(function() { return (loader.height - item.height) / 2 })
        item.scale = Qt.binding(function() {
            return Math.max(
                        item.width > 0 ? loader.width / item.width : 1,
                        item.height > 0 ? loader.height / item.height : 1)
        })
    }

    FadeAnimation {
        id: animation

        duration: 800
        running: false
    }

    Component {
        id: imageWallpaper

        ImageWallpaper {
        }
    }
}
