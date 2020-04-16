/*
 * Copyright (c) 2015 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    property int row
    property int column
    property Item _grid: launcherLayout

    x: _grid.x + column * _grid.cellWidth
    y: _grid.topMargin + row * _grid.cellHeight

    width: launcherLayout.cellWidth + (Screen.sizeCategory >= Screen.Large ? 0 : _grid.x)
    height: launcherLayout.cellHeight
    enabled: false
}
