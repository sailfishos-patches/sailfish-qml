/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Settings.Networking 1.0

ListItem {
    id: listItem

    property bool connected: modelData && (modelData.state == "online" || modelData.state == "ready")
    property bool highlightContent: connected || menuOpen || down
    property color baseColor: highlightContent ? Theme.highlightColor : Theme.primaryColor

    openMenuOnPressAndHold: false
    highlightedColor: "transparent"

    Image {
        id: icon
        x: Theme.paddingLarge
        anchors.verticalCenter: parent.verticalCenter
        source: "image://theme/icon-m-wlan-" + WlanUtils.getStrengthString(modelData.strength) + "?" + listItem.baseColor
    }

    Label {
        id: serviceName
        anchors {
            left: icon.right
            leftMargin: Theme.paddingSmall
            verticalCenter: parent.verticalCenter
            right: {
                if (bssidLabel.visible) {
                    return bssidLabel.left
                } else if (secureIcon.visible) {
                    return secureIcon.left
                } else {
                    return parent.right
                }
            }
            rightMargin: secureIcon.visible || bssidLabel.visible ? Theme.paddingSmall : Theme.paddingLarge
        }
        color: listItem.baseColor
        // TODO: find out why fading doesn't work in this application:
        //truncationMode: TruncationMode.Fade
        truncationMode: TruncationMode.Elide

        //% "Hidden network"
        text: modelData.name ? modelData.name : qsTrId("connection_selections-la-hidden_network")
    }

    Label {
        id: bssidLabel
        anchors {
            leftMargin: Theme.paddingMedium
            verticalCenter: parent.verticalCenter
            right: secureIcon.visible ? secureIcon.left : parent.right
            rightMargin: secureIcon.visible ? Theme.paddingSmall : Theme.paddingLarge
        }
        font.pixelSize: Theme.fontSizeExtraSmall
        visible: !modelData.name
        color: listItem.highlightContent ? Theme.secondaryHighlightColor : Theme.secondaryColor
        text: modelData.bssid
    }

    Image {
        id: secureIcon
        x: parent.width - width - Theme.paddingLarge
        anchors.verticalCenter: parent.verticalCenter
        source: "image://theme/icon-s-secure?" + listItem.baseColor
        visible: modelData.security ? modelData.security.indexOf("none") == -1 : false
    }
}

