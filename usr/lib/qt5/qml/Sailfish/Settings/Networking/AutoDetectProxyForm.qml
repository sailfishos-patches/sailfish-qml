/*
 * Copyright (c) 2012 - 2022 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    property QtObject network
    height: Math.max(Theme.itemSizeMedium, textItem.height + labelItem.height)

    Label {
        id: textItem
        text: network.proxy && network.proxy["URL"]
              ? network.proxy["URL"]
                //% "None currently active"
              : qsTrId("settings_network-la-auto_proxy_url_none")
        truncationMode: TruncationMode.Fade
        color: palette.highlightColor
        anchors {
            top: parent.top
            topMargin: Theme.paddingSmall
            left: parent.left
            right: parent.right
            leftMargin: Theme.horizontalPageMargin
            rightMargin: Theme.horizontalPageMargin
        }
    }

    Label {
        id: labelItem
        //% "Auto-detected PAC URL"
        text: qsTrId("settings_network-la-auto_proxy_detected_url")
        font.pixelSize: Theme.fontSizeSmall
        truncationMode: TruncationMode.Fade
        color: palette.secondaryHighlightColor
        bottomPadding: Theme.paddingMedium
        anchors {
            top: textItem.bottom
            topMargin: Theme.paddingSmall
            left: parent.left
            right: parent.right
            leftMargin: Theme.horizontalPageMargin
            rightMargin: Theme.horizontalPageMargin
        }
    }
}
