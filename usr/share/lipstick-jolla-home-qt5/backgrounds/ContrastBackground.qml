/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.Background 1.0
import "filters" as F
import "materials" as M
import org.nemomobile.lipstick 0.1

SilicaItem {
    id: background

    default property alias _data: contentItem.data
    property alias contentItem: contentItem
    property color contrastColor: palette.colorScheme === Theme.DarkOnLight
                ? Theme.rgba(Theme.lightPrimaryColor, Theme.opacityFaint)
                : Theme.rgba(palette.highlightDimmerColor, Theme.highlightBackgroundOpacity)
    property alias shadowVisible: shadow.visible

    FilteredImage {
        id: shadow

        property alias color: background.contrastColor

        x: source.x + Math.round(Theme.pixelRatio)
        y: source.y + Math.round(Theme.pixelRatio)
        width: source.width
        height: source.height

        sourceItem: source

        filters: F.ContrastFilter
    }


    ShaderEffectSource {
        id: source

        x: -16
        y: -16

        width: background.width - (2 * x)
        height: background.height - (2 * y)

        hideSource: true

        sourceItem: paddedContent

        Item {
            id: paddedContent

            width: source.width
            height: source.height

            Item {
                id: contentItem

                x: -source.x
                y: -source.y
                width: background.width
                height: background.height
            }
        }
    }
}
