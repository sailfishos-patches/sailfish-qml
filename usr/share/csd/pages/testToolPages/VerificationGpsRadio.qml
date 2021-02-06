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

CsdTestPage {
    id: page

    property PositionSource positionSource
    property bool _isGPSInitialized

    Component.onCompleted: initialiseTimer.start()
    function storeStateAndStart() {
        GpsStateRestorer.increaseConsumer()

        mdmBanner.active = (policy.value == false)

        if (!mdmBanner.active) {
            GpsStateRestorer.setGpsConfiguration()

            createPositionSource()

            _isGPSInitialized = true
        }
    }

    Component.onDestruction: {
        if (_isGPSInitialized) {
            GpsStateRestorer.decreaseConsumer()
        }

        if (!!positionSource) {
            positionSource.destroy()
            positionSource = null
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

    SilicaFlickable {
        anchors.fill: parent

        contentWidth: column.width
        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingMedium

            CsdPageHeader {
                //% "GPS"
                title: qsTrId("csd-he-gps")
            }

            DisabledByMdmBanner {
                id: mdmBanner
                active: false
                Timer {
                    id: disabledByMdmFailTimer
                    interval: 2500
                    running: true
                    onTriggered: {
                        if (mdmBanner.active) {
                            setTestResult(false)
                            testCompleted(true)
                        }
                    }
                }
            }

            Label {
                color: "red"
                //% "Turn on GPS positioning"
                text: qsTrId("csd-la-turn_on_gps_positioning")
                visible: !locationSettings.locationEnabled
                x: Theme.paddingLarge
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap
            }

            Label {
                color: "orange"
                //% "Turn on AGPS positioning for faster fix"
                text: qsTrId("csd-la-turn_on_agps_positioning")
                visible: locationSettings.locationEnabled &&
                         locationSettings.hereState !== LocationSettings.OnlineAGpsEnabled &&
                         locationSettings.mlsOnlineState !== LocationSettings.OnlineAGpsEnabled
                x: Theme.paddingLarge
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap
            }

            Label {
                x: Theme.paddingLarge
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap
                visible: satelliteTimer.running

                color: {
                    switch (gps.status) {
                    case Gps.StatusError: return "red"
                    case Gps.StatusUnavailable: return "red"
                    case Gps.StatusAcquiring:
                    case Gps.StatusAvailable: return "green"
                    default: return Theme.primaryColor
                    }
                }

                text: {
                    switch (gps.status) {
                    case Gps.StatusError:
                        //% "GPS in error state"
                        return qsTrId("csd-la-gps_error")
                    case Gps.StatusUnavailable:
                        //% "GPS is unavailable"
                        return qsTrId("csd-la-gps_unavailable")
                    case Gps.StatusAcquiring:
                    case Gps.StatusAvailable:
                        //% "Searching for satellites..."
                        return qsTrId("csd-la-searching_for_satellites")
                    default:
                        //% "Unknown GPS status"
                        return qsTrId("csd-la-unknown_gps_status")
                    }
                }
            }

            Label {
                x: Theme.paddingLarge
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap


                text: satelliteTimer.running
                        //% "Testing GPS Radio (%n seconds remaining)"
                      ? qsTrId("csd-la-testing_gps_radio", satelliteTimer.remaining)
                        //% "Test result:"
                      : qsTrId("csd-la-test_result")
            }

            ResultLabel {
                id: resultLabel

                x: Theme.paddingLarge
                visible: !satelliteTimer.running
            }

            Repeater {
                model: gps.satelliteInfo
                delegate: SatelliteDelegate {
                    width: page.width
                }
            }
        }
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
                    resultLabel.result = false
                    setTestResult(false)
                    testCompleted(false)
                }
            }
        }
    }

    Gps {
        id: gps

        onStatusChanged: {
            if (status === Gps.StatusError || status === Gps.StatusUnavailable) {
                satelliteTimer.stop()
                resultLabel.result = false
                setTestResult(false)
                testCompleted(false)
            }
        }

        onSatellitesInViewChanged: {
            if (satellitesInView > 0) {
                satelliteTimer.stop()
                resultLabel.result = true
                setTestResult(true)
                testCompleted(false)
            }
        }
    }

    LocationSettings { id: locationSettings }
}
