/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0


Item {
    property alias icon: icon.source
    property alias accountName: accountName.text
    property alias userName: userName.text

    anchors {
        left: parent.left
        leftMargin: Theme.horizontalPageMargin
        right: parent.right
        rightMargin: Theme.horizontalPageMargin
    }
    height: icon.height + Theme.paddingLarge

    Image {
        id: icon
        anchors.top: parent.top
        width: Theme.iconSizeLarge
        height: width
    }

    Column {
        anchors {
            left: icon.right
            leftMargin: Theme.paddingLarge
            right: parent.right
            verticalCenter: icon.verticalCenter
        }

        Label {
            id: accountName
            color: Theme.highlightColor
            truncationMode: TruncationMode.Fade
            font.pixelSize: Theme.fontSizeLarge
            width: parent.width
        }
        Label {
            id: userName
            width: parent.width
            visible: text !== ""
            truncationMode: TruncationMode.Fade
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.secondaryHighlightColor
        }
    }
}
