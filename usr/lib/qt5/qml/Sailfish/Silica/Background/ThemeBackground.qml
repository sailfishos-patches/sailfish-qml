/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.Background 1.0

Background {
    id: item

    property string backgroundMaterial: Theme._backgroundMaterial

    property color color: palette._wallpaperOverlayColor
    property color highlightColor: palette.highlightColor

    material: Materials[backgroundMaterial] || Materials.glass

    transformItem: __silica_applicationwindow_instance._rotatingItem || null
}
