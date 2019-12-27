/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import com.jolla.settings.system 1.0
import QtPositioning 5.0
import org.nemomobile.systemsettings 1.0
import Csd 1.0
import ".."

AutoTest {
    id: test

    property PositionSource positionSource

    property bool originalLocationEnabled
    property bool originalGpsEnabled
    property bool originalGpsFlightMode
    property bool originalMlsEnabled
    property int originalMlsOnlineState
    property int originalHereState

    function run() {
        gpsTechModel.initTestCase()
        initialiseTimer.start()
    }

    function storeStateAndStart() {
        originalLocationEnabled = locationSettings.locationEnabled
        originalGpsEnabled = locationSettings.gpsEnabled
        originalGpsFlightMode = locationSettings.gpsFlightMode
        originalMlsEnabled = locationSettings.mlsEnabled
        originalMlsOnlineState = locationSettings.mlsOnlineState
        originalHereState = locationSettings.hereState

        if (policy.value) {
            locationSettings.locationEnabled = true
            locationSettings.gpsEnabled = true
            locationSettings.gpsFlightMode = false
            locationSettings.mlsEnabled = true
            locationSettings.mlsOnlineState = LocationSettings.OnlineAGpsEnabled
            locationSettings.hereState = LocationSettings.OnlineAGpsEnabled
        }
        policy.positioningEnabled = locationSettings.locationEnabled
                                    && locationSettings.gpsEnabled
                                    && !locationSettings.gpsFlightMode

        if (policy.positioningEnabled) {
            createPositionSource()
        }
    }

    function createPositionSource() {
        positionSource = positionSourceComponent.createObject(null)
        satelliteTimer.remaining = 30
        satelliteTimer.restart()
    }

    PolicyValue {
        id: policy
        policyType: PolicyValue.LocationSettingsEnabled
        property bool positioningEnabled
        property Timer disabledByMdmFailTimer: Timer {
            interval: 2500
            running: true
            onTriggered: {
                if (!policy.positioningEnabled) {
                    setTestResult(false)
                }
            }
        }
    }

    Timer {
        // LocationSettings uses ConnMan NetworkTechnology to
        // access GPS power state (exposed as gpsFlightMode).
        // This is async, so give some time for it to initialise.
        id: initialiseTimer
        interval: 500
        onTriggered: storeStateAndStart()
    }

    Timer {
        id: positionSourceRecreationTimer
        interval: 1500
        onTriggered: createPositionSource()
    }

    Timer {
        id: satelliteTimer

        property int remaining

        interval: 1000
        repeat: true
        onTriggered: {
            --remaining

            if (remaining <= 0) {
                stop()

                if (gps.satellitesInView === 0) {
                    gpsTechModel.done(false)
                }
            }
        }
    }

    Gps {
        id: gps

        onStatusChanged: {
            if (status === Gps.StatusError || status === Gps.StatusUnavailable) {
                gpsTechModel.done(false)
            }
        }

        onSatellitesInViewChanged: {
            if (satellitesInView > 0) {
                gpsTechModel.done(true)
            }
        }
    }

    VerificationTechnologyModel {
        id: gpsTechModel
        name: "gps"

        onFinished: {
            test.setTestResult(success)

            if (policy.value) {
                locationSettings.hereState = originalHereState
                locationSettings.mlsOnlineState = originalMlsOnlineState
                locationSettings.mlsEnabled = originalMlsEnabled
                locationSettings.gpsFlightMode = originalGpsFlightMode
                locationSettings.gpsEnabled = originalGpsEnabled
                locationSettings.locationEnabled = originalLocationEnabled
            }

            if (!!positionSource) {
                positionSource.destroy()
                positionSource = null
            }
        }
    }

    LocationSettings { id: locationSettings }

    Component {
        id: positionSourceComponent
        PositionSource {
            active: true
            updateInterval: 1000

            onSourceErrorChanged: {
                if (sourceError === PositionSource.ClosedError) {
                    console.log("Position source backend closed, restarting...")
                    positionSourceRecreationTimer.restart()
                    positionSource.destroy()
                    positionSource = null
                }
            }
        }
    }
}
