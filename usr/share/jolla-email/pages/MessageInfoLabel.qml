/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Label {
    property bool header

    x: Theme.horizontalPageMargin
    width: parent.width - 2*x
    font.pixelSize: Theme.fontSizeSmall
    elide: Text.ElideRight
    maximumLineCount: 2
    wrapMode: Text.Wrap
    color: header ? Theme.secondaryHighlightColor : Theme.highlightColor
}
