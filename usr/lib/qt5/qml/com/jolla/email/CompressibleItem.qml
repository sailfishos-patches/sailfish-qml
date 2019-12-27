/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0

FocusScope {
    property bool compressible: true
    property real expandedHeight: children[0].implicitHeight
    property real compressionHeight
    readonly property bool compressed: height < 1

    height: expandedHeight - compressionHeight
    width: parent.width
    opacity: compressed ? 0 : Math.pow((height / expandedHeight), 3)
}
