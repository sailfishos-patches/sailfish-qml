/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import QtQuick.Window 2.0 as QtQuick
import Sailfish.Silica 1.0

Item {
    id: root

    signal canceled()
    signal triggered()
    signal mask(int x, int y, int w, int h)

    function execute() {
        //% "Turning Bluetooth off"
        remorse.execute(qsTrId("lipstick-jolla-home-la-bluetoothoff"));
    }

    function cancel() {
        remorse.cancel();
    }

    property int angle: QtQuick.Screen.angleBetween(QtQuick.Screen.orientation, Qt.PrimaryOrientation)
    property bool transpose: angle % 180 == 0

    property int w: transpose ? Screen.width : Screen.height
    property int h: transpose ? Screen.height : Screen.width

    property int maskW: transpose ? width : remorse.height
    property int maskH: transpose ? remorse.height : height
    property int maskX: angle == 90 ? width - remorse.height : 0
    property int maskY: angle == 180 ? height - remorse.height : 0
    onMaskWChanged: setMask()
    onMaskHChanged: setMask()
    onMaskXChanged: setMask()
    onMaskYChanged: setMask()
    function setMask() {
        root.mask(maskX, maskY, maskW, maskH)
    }

    Item {
        width: root.transpose ? Screen.width : Screen.height
        height: root.transpose ? Screen.height : Screen.width

        transform: Rotation {
            origin.x: (root.angle == 90 ? root.h : root.w) / 2
            origin.y: (root.angle < 270 ? root.h : root.w) / 2
            angle: root.angle
        }

        Rectangle {
            width: parent.width
            height: remorse.height
            color: Theme.rgba(Theme.highlightDimmerColor, Theme.opacityHigh)

            Item {
                id: remorseContainer
                anchors.fill: parent

                RemorsePopup {
                    id: remorse

                    onCanceled: root.canceled()
                    onTriggered: root.triggered()
                }
            }
        }
    }
}
