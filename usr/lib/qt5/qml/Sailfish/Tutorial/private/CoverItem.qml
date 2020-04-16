/*
 * Copyright (c) 2015 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Tutorial 1.0

BackgroundItem {
    property string name
    property Item item: switcher.getItem(name)
    x: item ? switcher.x + item.x : 0
    y: item ? switcher.y + item.y : 0

    width: switcher.coverSize.width
    height: switcher.coverSize.height
    contentItem.radius: Theme.paddingSmall
    highlightedColor: Theme.rgba(palette.highlightColor, Theme.highlightBackgroundOpacity)
    enabled: false
}
