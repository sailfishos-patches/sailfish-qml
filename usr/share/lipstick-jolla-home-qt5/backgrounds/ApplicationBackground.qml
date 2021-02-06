/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica 1.0

AmbienceBackgroundLoader {
    id: loader

    property real radius

    wallpaper: Component { AmbienceBackground {
        id: background

        radius: loader.radius
    } }
}
