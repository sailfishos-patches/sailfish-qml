/*
 * Copyright (c) 2015 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: delegateItem

    property int count
    property string thumbnail
    property alias title: titleLabel.text

    width: parent.width
    height: Theme.itemSizeExtraLarge

    Label {
        anchors {
            right: thumb.left
            rightMargin: Theme.paddingLarge
            verticalCenter: parent.verticalCenter
        }
        opacity: Theme.opacityLow
        text: count
        font.pixelSize: Theme.fontSizeLarge
    }

    Image {
        id: thumb
        x: Theme.itemSizeExtraLarge + Theme.horizontalPageMargin - Theme.paddingLarge
        width: Theme.itemSizeExtraLarge
        height: width
        opacity: delegateItem.down ? Theme.opacityHigh : 1
        source: Screen.sizeCategory >= Screen.Large
                ? Qt.resolvedUrl("file:///usr/share/sailfish-tutorial/graphics/tutorial-tablet-gallery-thumb-" + thumbnail + ".jpg")
                : Qt.resolvedUrl("file:///usr/share/sailfish-tutorial/graphics/tutorial-phone-gallery-thumb-" + thumbnail + ".jpg")
    }

    Label {
        id: titleLabel
        elide: Text.ElideRight
        font.pixelSize: Theme.fontSizeLarge
        anchors {
            left: thumb.right
            right: parent.right
            leftMargin: Theme.paddingLarge
            rightMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
        }
    }
}
