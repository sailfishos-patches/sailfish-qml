/****************************************************************************
**
** Copyright (C) 2014 Jolla Ltd.
** Contact: Joona Petrell <joona.petrell@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0
import Nemo.DBus 2.0
import org.nemomobile.lipstick 0.1
import com.jolla.lipstick 0.1

Loader {
    id: weatherLoader

    property alias advertiseWeather: weatherAdvertisementConfiguration.value
    property bool eventsVisible: eventsViewVisible

    onItemChanged: {
        if (item && source == "WeatherAdvertisement.qml") {
            item.closed.connect( function() { source = "" } )
        }
    }
    onEventsVisibleChanged: {
        // Refresh banner file status whenever events view is shown
        if (eventsVisible) {
            Desktop.refreshWeatherAvailable()
            if (Desktop.weatherAvailable && advertiseWeather) {
                advertiseWeather = false
            }
        }
    }

    width: parent.width
    height: Math.max(Theme.paddingLarge, item ? item.implicitHeight : 0)
    source: Desktop.weatherAvailable ? "WeatherBanner.qml"
                                     : advertiseWeather ? "WeatherAdvertisement.qml"
                                                        : ""

    ConfigurationValue {
        id: weatherAdvertisementConfiguration
        key: "/desktop/lipstick-jolla-home/advertise_weather"
        defaultValue: true
    }
}
