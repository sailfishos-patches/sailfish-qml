/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import QtQuick.Window 2.1 as QtQuick
import org.nemomobile.lipstick 0.1

FocusScope {
    id: wrapper

    property Item window
    property bool mapped: true
    property bool exposed: true
    property bool ignoreHide
    property int windowType
    property bool closeHinted
    property real windowOpacity: 1.0
    property rect backgroundRect: Qt.rect(0, 0, width, height)

    width: window ? window.width : 0
    height: window ? window.height : 0

    property int orientation: window && window.surface
                ? (window.surface.contentOrientation != Qt.PrimaryOrientation ? window.surface.contentOrientation : QtQuick.Screen.primaryOrientation)
                : Lipstick.compositor.screenOrientation
    property bool renderBackground: window
                && window.surface
                && window.surface.windowProperties.BACKGROUND_VISIBLE != undefined
                && window.surface.windowProperties.BACKGROUND_VISIBLE
    property bool renderDialogBackground: window
                && window.surface
                && window.surface.windowProperties.USE_DIALOG_BACKGROUND != undefined
                && window.surface.windowProperties.USE_DIALOG_BACKGROUND
    property bool hasCover
    property bool hasChildWindows

    Component.onCompleted: if (window) { window.parent = wrapper }

    onExposedChanged: {
        if (!exposed) {
            ignoreHide = true
        }
    }
}
