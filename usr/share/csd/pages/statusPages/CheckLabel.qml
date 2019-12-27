/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.2
import Sailfish.Silica 1.0

Row {
    property alias text: label.text
    property bool checked

    spacing: Theme.paddingSmall
    Rectangle {
        height: label.height - 3*Theme.paddingSmall
        width: height
        anchors.verticalCenter: parent.verticalCenter
        border.width: 1
        border.color: Theme.primaryColor
        radius: Theme.paddingSmall
        color: "transparent"
        Rectangle {
            anchors {
                fill: parent
                margins: Theme.paddingSmall/2
            }
            color: checked ? "#AF00ff00" : "transparent"
            radius: Theme.paddingSmall/2
        }
    }
    Label {
        id: label
    }
}
