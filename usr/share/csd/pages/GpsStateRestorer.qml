/*
    Copyright (c)  2020 Open Mobile Platform LLC
*/

pragma Singleton

import QtQuick 2.0
import com.jolla.settings.system 1.0
import QtPositioning 5.0
import org.nemomobile.systemsettings 1.0

Item {
    property bool localLocationEnabled
    property bool localGpsEnabled
    property bool localGpsFlightMode
    property bool localMlsEnabled
    property int localMlsOnlineState
    property int localHereState
    property int gpsActiveTests

    function increaseConsumer() {
        if (gpsActiveTests === 0) {
            localLocationEnabled = locationSettings.locationEnabled
            localGpsEnabled = locationSettings.gpsEnabled
            localGpsFlightMode = locationSettings.gpsFlightMode
            localMlsEnabled = locationSettings.mlsEnabled
            localMlsOnlineState = locationSettings.mlsOnlineState
            localHereState = locationSettings.hereState
        }
        gpsActiveTests++
    }

    function decreaseConsumer() {
        gpsActiveTests--

        if (gpsActiveTests === 0) {
            locationSettings.hereState = localHereState
            locationSettings.mlsOnlineState = localMlsOnlineState
            locationSettings.mlsEnabled = localMlsEnabled
            locationSettings.gpsFlightMode = localGpsFlightMode
            locationSettings.gpsEnabled = localGpsEnabled
            locationSettings.locationEnabled = localLocationEnabled
        }
    }

    function setGpsConfiguration() {
        if (!locationSettings.locationEnabled)
            locationSettings.locationEnabled = true
        if (!locationSettings.gpsEnabled)
            locationSettings.gpsEnabled = true
        if (locationSettings.gpsFlightMode)
            locationSettings.gpsFlightMode = false
        if (!locationSettings.mlsEnabled)
            locationSettings.mlsEnabled = true
        if (locationSettings.mlsOnlineState === LocationSettings.OnlineAGpsDisabled)
            locationSettings.mlsOnlineState = LocationSettings.OnlineAGpsEnabled
        if (locationSettings.hereState === LocationSettings.OnlineAGpsDisabled)
            locationSettings.hereState = LocationSettings.OnlineAGpsEnabled
    }

    LocationSettings { id: locationSettings }
}


