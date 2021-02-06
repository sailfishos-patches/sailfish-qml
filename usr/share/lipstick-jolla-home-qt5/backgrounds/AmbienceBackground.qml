/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.Background 1.0
import org.nemomobile.lipstick 0.1

ThemeBackground {
    id: background

    // AmbienceBackgroundLoader
    property int colorScheme
    property color highlightColor

    palette {
        colorScheme: background.colorScheme
        highlightColor: background.highlightColor
    }

    patternItem: Lipstick.compositor.wallpaper.applicationBackgroundOverlayImage
    transformItem: Lipstick.compositor.wallpaper.transformItem
}
