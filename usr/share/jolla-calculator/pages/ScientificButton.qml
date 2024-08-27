/*
 * Copyright (c) 2021 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

CalculatorButton {
    font.pixelSize: Theme.fontSizeMedium
    height: implicitWidth * 0.75
    width: pageStack.currentPage.isLandscape ? implicitWidth : implicitWidth * (5/6)
}
