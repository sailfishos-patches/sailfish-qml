/****************************************************************************
 **
 ** Copyright (c) 2014 - 2019 Jolla Ltd.
 ** Copyright (c) 2020 Open Mobile Platform LLC.
 **
 ****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1
import "../backgrounds"

StackLayer {
    id: dialogLayer

    objectName: "dialogLayer"
    childrenOpaque: false

    onQueueWindow: contentItem.prependItem(window)

    underlayItem.children: [
        Rectangle {
            width: dialogLayer.width
            height: dialogLayer.height
            color: Theme.highlightDimmerColor
            visible: dialogLayer.renderDialogBackground
            opacity: Theme.opacityLow
        },

        DialogBackground {
            visible: dialogLayer.renderDialogBackground
            x: dialogLayer.backgroundRect.x
            y: dialogLayer.backgroundRect.y
            width: dialogLayer.backgroundRect.width
            height: dialogLayer.backgroundRect.height
        }
    ]
}
