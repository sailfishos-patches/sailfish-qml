/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.Background 1.0

Background {
    property color color: Theme.rgba(
                palette.highlightBackgroundColor, Theme.highlightBackgroundOpacity)

    material: color.a === 1.0
              ? Materials.opaqueColor
              : Materials.translucentColor
}
