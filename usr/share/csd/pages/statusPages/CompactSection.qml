/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    property alias title: titleLabel.text
    default property alias children: content.data

    height: content.y + content.height
    opacity: content.height > 0 ? 1.0 : 0.0

    function _updateContentPos() {
        content.y = content.children[0].width + titleLabel.width + Theme.paddingLarge < width ? 0 : titleLabel.height
    }

    Column {
        id: content
        width: parent.width
    }

    Connections {
        target: content.children[0]
        onWidthChanged: _updateContentPos()
    }

    Label {
        id: titleLabel
        anchors.right: parent.right
        horizontalAlignment: Text.AlignRight
        width: Math.min(implicitWidth, parent.width)
        onWidthChanged: _updateContentPos()
        font.pixelSize: Theme.fontSizeSmall
        truncationMode: TruncationMode.Fade
        color: Theme.highlightColor
    }
}
