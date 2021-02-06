/*
 * Copyright (c) 2015 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.Background 1.0
import org.nemomobile.lipstick 0.1

SilicaItem {
    id: item

    // SynchronizedWallpaperLoader
    property int colorScheme
    property color highlightColor
    property alias sourceItem: background.sourceItem

    // DimmedBackgroundLoader
    property bool dimming
    property bool dimmed
    property real percentageDimmed

    // DimmedBackgroundLoader + HomeMaterials / LockscreenMaterials
    property Item homeWallpaper

    // HomeMaterials / LockscreenMaterials
    property color color: palette.colorScheme === Theme.DarkOnLight
            ? Theme.rgba(Theme.lightPrimaryColor, 0.4)
            : Theme.rgba(palette.highlightDimmerColor, Theme.highlightBackgroundOpacity)

    property QtObject materials

    implicitWidth: item.implicitWidth
    implicitHeight: item.implicitHeight

    palette {
        colorScheme: item.colorScheme
        highlightColor: item.highlightColor
    }

    Background {
        id: background

        property alias color: item.color
        property alias highlightColor: item.highlightColor
        property alias homeTexture: item.homeWallpaper
        property alias percentageDimmed: item.percentageDimmed

        width: item.width
        height: item.height

        material: {
            if (!item.materials) {
                return null
            } else if (item.dimming) {
                return item.materials.dimming
            } else if (item.dimmed) {
                return item.materials.dimmed
            } else {
                return item.materials.undimmed
            }
        }

        transformItem: Lipstick.compositor.wallpaper.transformItem
    }
}
