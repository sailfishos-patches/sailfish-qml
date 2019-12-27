/****************************************************************************
**
** Copyright (C) 2015 Jolla Ltd.
** Contact: Raine Makelainen <raine.makelainen@jolla.com>
**
****************************************************************************/

import QtQuick 2.1
import Sailfish.Silica 1.0

Image {
    property real offset
    property bool exposed
    property bool animate: true
    property alias opacityBehavior: opacityBehavior

    source: "image://theme/graphic-edge-swipe-handle-top"

    anchors.horizontalCenter: parent.horizontalCenter
    y: offset - height

    opacity: exposed ? 1.0 : 0.0

    Behavior on opacity {
        id: opacityBehavior
        SequentialAnimation {
            FadeAnimation { duration: animate ? 200 : 0 }
            ScriptAction { script: animate = true }
        }
    }
}
