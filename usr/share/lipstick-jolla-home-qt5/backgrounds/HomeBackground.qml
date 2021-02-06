/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import "materials" as M

DimmedBackgroundLoader {
    wallpaper: Component { DimmedBackground {
        materials: M.HomeMaterials
    } }
}
