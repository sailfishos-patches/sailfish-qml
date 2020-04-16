/*
 * Copyright (c) 2015 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0

SwitcherGrid {
    rows: 2
    columns: 3
    coverSize: _largeScreen ? Theme.coverSizeLarge : Theme.coverSizeSmall

    function getItem(name) {
        var model = repeater.model
        for (var i = 0; i < model.length; i++) {
            if (model[i] == name) {
                return repeater.itemAt(i)
            }
        }
    }

    Repeater {
        id: repeater
        model: _largeScreen
               ? ["people", "clock", "camera", "settings", "browser", "gallery"]
               : ["people", "clock", "store", "settings", "browser", "gallery"]

        Image {
            width: coverSize.width
            height: coverSize.height
            source: _largeScreen
                    ? Qt.resolvedUrl("file:///usr/share/sailfish-tutorial/graphics/tutorial-tablet-" + modelData + "-cover.png")
                    : Qt.resolvedUrl("file:///usr/share/sailfish-tutorial/graphics/tutorial-phone-" + modelData + "-cover.png")
        }
    }
}
