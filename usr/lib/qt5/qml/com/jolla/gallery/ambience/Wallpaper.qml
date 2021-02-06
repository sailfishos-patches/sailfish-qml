/*
 * Copyright (c) 2014 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.1
import Sailfish.Silica 1.0
import Sailfish.Silica.Background 1.0

ThemeBackground {
    id: wallpaper

    visible: sourceItem && sourceItem.status === Image.Ready

    patternItem: glassTextureImage

    Image {
        id: glassTextureImage
        visible: false
        source: Theme._patternImage
    }
}
