/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica 1.0

SynchronizedWallpaperLoader {
    id: applicationLoader

    function properties(item, ambience) {
        return {
            "sourceItem": item,
            "imageUrl": ambience.applicationWallpaperUrl,
            "wallpaperFilter": ambience.wallpaperFilter || "",
            "colorScheme": ambience.colorScheme
        }
    }

    implicitWidth: Math.max(
                item ? Math.min(item.implicitWidth, item.implicitHeight) : 0,
                replacedItem ? Math.min(replacedItem.implicitWidth, replacedItem.implicitHeight) : 0)
    implicitHeight: implicitWidth

    wallpaper: Component { ApplicationWallpaper {} }
}
