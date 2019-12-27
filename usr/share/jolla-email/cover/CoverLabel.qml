/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Label {
    x: Theme.paddingLarge
    width: parent.width - Theme.paddingLarge*2
    color: Theme.highlightColor
    elide: Text.ElideRight
    wrapMode: Text.Wrap
}
