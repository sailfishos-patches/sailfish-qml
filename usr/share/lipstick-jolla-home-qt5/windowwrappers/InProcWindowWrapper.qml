/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import QtQuick.Window 2.1 as QtQuick

WindowWrapperBase {
    z: window && window.rootItem ? window.rootItem.z : 0
    orientation: window && window.rootItem && window.rootItem.orientation != undefined
                ? window.rootItem.orientation
                : QtQuick.Screen.primaryOrientation
    renderDialogBackground: window
                && window.rootItem
                && window.rootItem._backgroundVisible != undefined
                && window.rootItem._backgroundVisible
    hasChildWindows: true
    windowOpacity: window && window.rootItem && window.rootItem._windowOpacity != undefined
                ? window.rootItem._windowOpacity
                : 1.0
    backgroundRect: window && window.rootItem && window.rootItem._backgroundRect != undefined
                    ? window.rootItem._backgroundRect
                    : Qt.rect(0, 0, width, height)
}
