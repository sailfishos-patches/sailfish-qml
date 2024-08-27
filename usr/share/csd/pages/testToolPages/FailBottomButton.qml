/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

BottomButton {
    color: "red"
    //% "Fail"
    text: qsTrId("csd-la-fail")
    property string reason: ""

    Label {
        anchors.bottom: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: Theme.paddingLarge
        wrapMode: Text.Wrap
        visible: parent.visible && text
        text: parent.reason
    }
}
