/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.Background 1.0
import org.nemomobile.lipstick 0.1

WallpaperLoader {
    id: homeLoader

    property alias transitionDelay: pauseAnimation.duration

    wallpaper: Component { HomeWallpaper {} }

    animating: backgroundTransition.running

    onAnimate: {
        if (item) {
            item.opacity = 0
        }
        backgroundTransition.restart()
    }
    onCompleteAnimation: backgroundTransition.complete()

    onAboutToComplete: imageUrl = Qt.binding(function() { return Lipstick.compositor.wallpaper.ambience.wallpaperUrl })

    SequentialAnimation {
        id: backgroundTransition

        PauseAnimation {
            id: pauseAnimation
        }
        FadeAnimation {
            target: homeLoader.item
            duration: 800
            from: 0.0
            to: 1.0
        }
    }
}
