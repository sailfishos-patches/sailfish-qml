/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Silica.Background 1.0

Image {
    property url imageUrl
    property string wallpaperFilter

    asynchronous: AnimatedLoader.asynchronous
    sourceSize.height: Screen.height
    cache: false

    source: imageUrl != ""
            ? "image://silica-square/" + encodeURIComponent(imageUrl)
            : ""

    AnimatedLoader.status: {
        switch (status) {
        case Image.Loading: return AnimatedLoader.Loading
        case Image.Ready: return AnimatedLoader.Ready
        case Image.Null:
        case Image.Error:
        default: return AnimatedLoader.Error
        }
    }
}
