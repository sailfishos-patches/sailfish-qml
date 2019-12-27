/****************************************************************************
**
** Copyright (C) 2014 Jolla Ltd.
** Contact: Joona Petrell <joona.petrell@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Weather 1.0 as Weather
import Nemo.Configuration 1.0

Item {
    width: parent.width
    implicitHeight: weatherBanner.enabled ? weatherBanner.height : noticeLoader.height

    Loader {
        id: noticeLoader

        width: parent.width
        height: item ? item.height : 0

        source: !weatherBanner.enabled ? "WeatherNotice.qml" : ""
    }

    Weather.WeatherBanner {
        id: weatherBanner

        autoRefresh: true
        active: eventsViewVisible
        expanded: configuration.value
        onExpandedChanged: configuration.value = expanded
    }

    ConfigurationValue {
        id: configuration
        key: "/lipstick/weatherbanner/expanded"
        defaultValue: true
    }
}
