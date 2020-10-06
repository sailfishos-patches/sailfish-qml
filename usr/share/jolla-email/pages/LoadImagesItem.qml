/*
 * Copyright (c) 2018 – 2019 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: loadImagesArea

    signal closeClicked()

    height: Theme.itemSizeExtraSmall

    Icon {
        id: fileImage
        x: Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter
        source: "image://theme/icon-m-file-image"
    }

    Label {
        anchors {
            left: fileImage.right
            right: closeButton.left
            margins: Theme.paddingMedium
        }
        height: loadImagesArea.height

        //% "Load images"
        text: qsTrId("jolla-email-la-load_images")
        font.pixelSize: Theme.fontSizeSmall
        verticalAlignment: Text.AlignVCenter
        truncationMode: TruncationMode.Fade
    }

    IconButton {
        id: closeButton

        icon.source: "image://theme/icon-m-input-remove"

        width: loadImagesArea.height
        height: loadImagesArea.height

        x: loadImagesArea.width - width - Theme.horizontalPageMargin

        onClicked: loadImagesArea.closeClicked()
    }
}
