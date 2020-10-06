/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.5
import Sailfish.Silica 1.0
import com.jolla.settings.system 1.0

BackgroundItem {
    property alias name: label.text
    property alias type: icon.type
    property alias uid: icon.uid
    property bool textHighlighted: highlighted
    property bool showYou

    UserIcon {
        id: icon
        anchors {
            left: parent.left
            leftMargin: (parent.height + Theme.paddingMedium - width) / 2
            verticalCenter: parent.verticalCenter
        }
        highlighted: textHighlighted
        x: Theme.horizontalPageMargin
    }

    Label {
        id: youLabel
        anchors {
            left: icon.right
            leftMargin: Theme.paddingSmall
            verticalCenter: parent.verticalCenter
        }
        color: label.color
        highlighted: textHighlighted
        //: "You" means the current user, %1 is a bullet character
        //% "You %1 "
        text: qsTrId("lipstick_jolla_home-la-topmenu_you").arg("\u2022")
        visible: showYou && current
    }

    Label {
        id: label
        anchors {
            left: showYou && current ? youLabel.right : icon.right
            leftMargin: showYou && current ? 0 : Theme.paddingSmall
            right: parent.right
            rightMargin: Theme.paddingSmall
            verticalCenter: parent.verticalCenter
        }
        highlighted: textHighlighted
        truncationMode: TruncationMode.Fade
    }
}
