/****************************************************************************
**
** Copyright (C) 2015 Jolla Ltd.
** Contact: Raine Makelainen <raine.makelainen@jolla.com>
**
****************************************************************************/

import QtQuick 2.1
import Sailfish.Silica 1.0

FocusScope {
    property bool destroyWhenHidden

    width: parent.width
    height: parent.height
    enabled: opacity === 1.0
    opacity: 0.0
    onOpacityChanged: {
        if (opacity === 0.0 && destroyWhenHidden) {
            destroy()
        }
    }

    Behavior on opacity { FadeAnimation {} }
}
