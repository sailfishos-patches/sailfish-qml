/*
 * Copyright (c) 2015 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    property double row
    property double column

    property double _rows: 6
    property double _columns: 4

    property double _horizontalMargin: Screen.sizeCategory >= Screen.Large ? 120 : 0
    property double _verticalMargin: Screen.sizeCategory >= Screen.Large ? 50 : 20
    property double _cellWidth: Screen.sizeCategory >= Screen.Large ? 324 : 135
    property double _cellHeight: Screen.sizeCategory >= Screen.Large ? 320 : 150

    x: (_horizontalMargin + column*_cellWidth) * xScale
    y: (_verticalMargin + row*_cellHeight) * yScale

    width: _cellWidth * xScale
    height: _cellHeight * yScale
    enabled: false
}
