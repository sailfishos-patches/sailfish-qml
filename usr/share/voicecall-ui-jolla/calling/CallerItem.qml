/*
 * Copyright (c) 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import "../pages/callhistory"

CallHistoryItem {
    id: root

    property alias secondaryText: secondaryLabel.text
    rightMargin: Theme.horizontalPageMargin + secondaryLabel.width
    dateColumnVisible: false
    y: Theme.paddingSmall
    z: 1

    palette {
        primaryColor: Theme.lightPrimaryColor
        highlightColor: Theme.lightPrimaryColor
        secondaryColor: Theme.lightSecondaryColor
        secondaryHighlightColor: Theme.lightSecondaryColor
    }
    _backgroundColor: "transparent"

    Rectangle {
        anchors {
            topMargin: -root.y
            bottomMargin: -root.y
            fill: parent
        }
        color: Qt.tint("#00bb15", Qt.rgba(0, 0, 0, highlighted ? 0.3 : 0.0))
        z: -1
    }

    Label {
        id: secondaryLabel
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: Theme.horizontalPageMargin
    }
}
