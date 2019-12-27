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
    property var _cloudIcons: ["cloud-3", "rain-snow-2", "rain-water-2", "rain-water-4"]

    width: icon.width
    height: icon.height

    Image {
        id: icon

        opacity: _iconToggle ? 0.0 : 1.0
        Behavior on opacity { FadeAnimation { duration: 1000 } }
        source: "image://theme/graphic-m-weather-cloud-day-0?" + (highlighted ? Theme.highlightColor : Theme.primaryColor)
    }

    Image {
        opacity: _iconToggle ? 1.0 : 0.0
        Behavior on opacity { FadeAnimation { duration: 1000 } }
        onOpacityChanged: if (opacity === 0) _index = (_index + 1) % _cloudIcons.length
        source: "image://theme/graphic-m-weather-" + _cloudIcons[_index] + "?" + (highlighted ? Theme.highlightColor : Theme.primaryColor)
    }

    Timer {
        repeat: true
        interval: 3000
        running: eventsViewVisible
        onTriggered: _iconToggle = !_iconToggle
    }
}

