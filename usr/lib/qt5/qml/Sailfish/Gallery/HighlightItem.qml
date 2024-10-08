/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Raine Mäkeläinen <raine.makelainen@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0

/*!
  \inqmlmodule Sailfish.Gallery
*/
Rectangle {
    property bool active
    property real highlightOpacity: Theme.opacityHigh

    color: Theme.highlightBackgroundColor
    opacity: active ? highlightOpacity : 0.0
    Behavior on opacity {
        FadeAnimation {
            duration: 100
        }
    }
}
