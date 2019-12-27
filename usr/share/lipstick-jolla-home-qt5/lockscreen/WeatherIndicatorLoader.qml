/****************************************************************************
**
** Copyright (C) 2018 Jolla Ltd.
** Contact: Bea Lam <bea.lam@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1
import com.jolla.lipstick 0.1

Loader {
    id: root

    property bool active
    property int temperatureFontPixelSize: Theme.fontSizeHuge

    source: Desktop.weatherAvailable ? "WeatherIndicator.qml" : ""

    onItemChanged: {
        if (item) {
            item.active = Qt.binding(function() { return root.active })
            item.temperatureFont.pixelSize = Qt.binding(function() { return root.temperatureFontPixelSize })
        }
    }

    Connections {
        target: Lipstick.compositor
        onScreenIsLockedChanged: {
            if (Lipstick.compositor.screenIsLocked) {
                Desktop.refreshWeatherAvailable()
            }
        }
    }
}
