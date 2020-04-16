/****************************************************************************
**
** Copyright (C) 2015 Jolla Ltd.
** Contact: Aaron McCarthy <aaron.mccarthy@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    property int _index
    property bool _iconToggle
    property var _cloudIcons: ["d300", "d422", "d420", "d440"]

    width: icon.width
    height: icon.height

    Image {
        id: icon

        opacity: _iconToggle ? 0.0 : 1.0
        Behavior on opacity { FadeAnimation { duration: 2000 } }
        source: "image://theme/icon-m-weather-d000" + (highlighted ? ("?" + Theme.highlightColor) : "")
    }

    Image {
        opacity: _iconToggle ? 1.0 : 0.0
        Behavior on opacity { FadeAnimation { duration: 2000 } }
        onOpacityChanged: if (opacity === 0) _index = (_index + 1) % _cloudIcons.length
        source: "image://theme/icon-m-weather-" + _cloudIcons[_index] + (highlighted ? ("?" + Theme.highlightColor)
                                                                                     : "")
    }

    Timer {
        repeat: true
        interval: 7000
        running: eventsViewVisible
        onTriggered: _iconToggle = !_iconToggle
    }
}
