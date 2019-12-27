/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Flow {
    property alias title: label.text
    property alias value: resultLabel.text

    x: Theme.paddingLarge
    width: parent.width - 2*x
    spacing: Theme.paddingMedium

    Label {
        id: label
        height: Theme.itemSizeExtraSmall
        verticalAlignment: Text.AlignVCenter
    }

    Rectangle {
        color: Theme.primaryColor
        width: 100
        height: Theme.itemSizeExtraSmall
        Label {
            id: resultLabel
            anchors.centerIn: parent
            color: Theme.overlayBackgroundColor
        }
    }
}
