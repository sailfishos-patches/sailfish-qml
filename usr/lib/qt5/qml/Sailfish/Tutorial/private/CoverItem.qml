/*
 * Copyright (c) 2015 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Tutorial 1.0

BackgroundItem {
    property int row
    property int column

    property int _horizontalMargin: applicationSwitcher.horizontalMargin
    property int _verticalMargin: applicationSwitcher.verticalMargin
    property int _horizontalSpacing: applicationSwitcher.horizontalSpacing
    property int _verticalSpacing: applicationSwitcher.verticalSpacing

    x: _horizontalMargin + column * width + column * _horizontalSpacing
    y: _verticalMargin + row * height + row * _verticalSpacing
    width: {
        if (Screen.width > 1080) {
            352 * xScale
        } else if (Screen.height <= 2519) {
            136 * xScale
        } else {
            294
        }
    }
    height: {
        if (Screen.width > 1080) {
            562 * yScale
        } else if (Screen.height <= 2519) {
            218 * yScale
        } else {
            470
        }
    }

    highlightedColor: Theme.rgba(palette.highlightColor, Theme.highlightBackgroundOpacity)
    enabled: false
}
