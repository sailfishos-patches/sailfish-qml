/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    property alias text: label.text

    Label {
        id: label

        anchors.verticalCenter: parent.verticalCenter
        x: Theme.paddingLarge
        color: highlighted ? Theme.highlightColor : Theme.primaryColor
    }
}

