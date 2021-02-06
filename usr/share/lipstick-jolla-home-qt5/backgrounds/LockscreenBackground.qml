/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1
import "../lockscreen"
import "materials" as M


DimmedBackgroundLoader {
    id: background

    property alias vignette: vignette

    wallpaper: Component { DimmedBackground {
        materials: M.LockscreenMaterials
    } }

    Vignette {
        id: vignette

        active: false
        width: background.width
        height: background.height
        openRadius: 0.75
        softness: 0.7
        animated: lipstickSettings.blankingPolicy === "default"
        z: 1
    }
}
