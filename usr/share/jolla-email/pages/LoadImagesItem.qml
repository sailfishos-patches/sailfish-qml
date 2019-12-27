/*
 * Copyright (c) 2018 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: loadImagesArea

    height: Theme.itemSizeExtraSmall

    Image {
        id: fileImage
        x: Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter
        source: "image://theme/icon-m-file-image" + (loadImagesArea.highlighted ? ("?" + Theme.highlightColor) : "")
    }

    Label {
        anchors {
            left: fileImage.right
            leftMargin: Theme.paddingMedium
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
        }
        height: Theme.itemSizeExtraSmall
        //% "Load images"
        text: qsTrId("jolla-email-la-load_images")
        verticalAlignment: Text.AlignVCenter
        color: loadImagesArea.highlighted ? Theme.highlightColor : Theme.primaryColor
        truncationMode: TruncationMode.Fade
    }
}
