/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Silica.Background 1.0

ThemeWallpaper {
    property url imageUrl

    source: imageUrl != ""
            ? "image://silica-square/" + encodeURIComponent(imageUrl)
            : ""

    asynchronous: AnimatedLoader.asynchronous
    cache: false
    sourceSize.height: Screen.height

    AnimatedLoader.status: {
        switch (status) {
        case Image.Loading: return AnimatedLoader.Loading
        case Image.Ready: return AnimatedLoader.Ready
        case Image.Null:
            return sourceItem ? AnimatedLoader.Ready : AnimatedLoader.Error
        case Image.Error:
        default: return AnimatedLoader.Error
        }
    }
}
