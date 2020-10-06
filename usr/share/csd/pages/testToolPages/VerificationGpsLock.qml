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
import org.nemomobile.time 1.0
import org.nemomobile.systemsettings 1.0
import Csd 1.0
import ".."

CsdTestPage {
    id: page

    property PositionSource positionSource

    property var testStartTime: new Date()

    property string assistedSource
    property var assistTimestamp: new Date()
    property bool assistedLatitudeValid
    property bool assistedLongitudeValid
    property var assistedPosition: QtPositioning.coordinate()

    property var satelliteTimestamp: new Date()
    property bool satelliteLatitudeValid
    property bool satelliteLongitudeValid
    property bool satelliteAltitudeValid
    property var satellitePosition: QtPositioning.coordinate()
    property bool satelliteHorizontalAccuracyValid
    property double satelliteHorizontalAccuracy
    property bool satelliteVerticalAccuracyValid
    property double satelliteVerticalAccuracy

    property bool _originalLocationEnabled
    property bool _originalGpsEnabled
    property bool _originalGpsFlightMode
    property bool _originalMlsEnabled
    property int _originalMlsOnlineState
    property int _originalHereState

    property bool _isGPSInitialized

    Component.onCompleted: initialiseTimer.start()
    function storeStateAndStart() {
        _originalLocationEnabled = locationSettings.locationEnabled
        _originalGpsEnabled = locationSettings.gpsEnabled
        _originalGpsFlightMode = locationSettings.gpsFlightMode
        _originalMlsEnabled = locationSettings.mlsEnabled
        _originalMlsOnlineState = locationSettings.mlsOnlineState
        _originalHereState = locationSettings.hereState

        mdmBanner.active = (policy.value == false)

        if (!mdmBanner.active) {
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

            createPositionSource()

            _isGPSInitialized = true
        }

    }

    Component.onDestruction: {
        if (_isGPSInitialized) {
            locationSettings.hereState = _originalHereState
            locationSettings.mlsOnlineState = _originalMlsOnlineState
            locationSettings.mlsEnabled = _originalMlsEnabled
            locationSettings.gpsFlightMode = _originalGpsFlightMode
            locationSettings.gpsEnabled = _originalGpsEnabled
            locationSettings.locationEnabled = _originalLocationEnabled
        }

        if (!!positionSource) {
            positionSource.destroy()
            positionSource = null
        }
    }

    function createPositionSource() {
        positionSource = positionSourceComponent.createObject(null)
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

            onPositionChanged: {
                if (position.timestamp <= testStartTime) {
                    // Last known position

                    //% "Last known position"
                    assistedSource = qsTrId("csd-la-last_known_position")
                    assistTimestamp = position.timestamp
                    assistedLatitudeValid = position.latitudeValid
                    assistedLongitudeValid = position.longitudeValid
                    assistedPosition = position.coordinate
                } else if (position.altitudeValid && (position.verticalAccuracyValid || position.horizontalAccuracyValid)) {
                    // Bit of a hack, expect GPS to return altitude information and that assisted
                    // positioning methods do not.
                    // Please note that some GPS modules don't provide verticalAccuracy (only horizontalAccuracy)

                    // Satellite provided position
                    satelliteTimestamp = position.timestamp
                    satelliteLatitudeValid = position.latitudeValid
                    satelliteLongitudeValid = position.longitudeValid
                    satelliteAltitudeValid = position.altitudeValid
                    satellitePosition = position.coordinate
                    satelliteHorizontalAccuracyValid = position.horizontalAccuracyValid
                    satelliteHorizontalAccuracy = position.horizontalAccuracy
                    satelliteVerticalAccuracyValid = position.verticalAccuracyValid
                    satelliteVerticalAccuracy = position.verticalAccuracy

                    setTestResult(true)
                    testCompleted(false)

                } else {
                    //% "Non-satellite position"
                    assistedSource = qsTrId("csd-la-non_satellite_position")
                    assistTimestamp = position.timestamp
                    assistedLatitudeValid = position.latitudeValid
                    assistedLongitudeValid = position.longitudeValid
                    assistedPosition = position.coordinate
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

            CsdPageHeader {
                //% "GPS satellite lock"
                title: qsTrId("csd-he-gps_satellite_lock")
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
                         (locationSettings.hereState !== LocationSettings.OnlineAGpsEnabled ||
                          locationSettings.mlsOnlineState !== LocationSettings.OnlineAGpsEnabled)
                x: Theme.paddingLarge
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap
            }

            SectionHeader {
                //% "Satellite position"
                text: qsTrId("csd-he-satellite_position")
            }

            Label {
                x: Theme.paddingLarge
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap

                color: {
                    switch (gps.status) {
                    case Gps.StatusError: return "red"
                    case Gps.StatusUnavailable: return "red"
                    case Gps.StatusAcquiring: return "orange"
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
                        //% "Acquiring satellite position fix..."
                        return qsTrId("csd-la-acquiring_first_position_fix")
                    case Gps.StatusAvailable:
                        //% "Have GPS fix"
                        return qsTrId("csd-la-have_gps_fix")
                    default:
                        //% "Unknown GPS status"
                        return qsTrId("csd-la-unknown_gps_status")
                    }
                }
            }

            Item {
                height: Theme.paddingMedium
                width: parent.width
            }

            Label {
                //% "Time since last fix: %0s"
                text: qsTrId("csd-la-time_since_last_fix").arg(fixClock.secondsSinceSatelliteFix)
                x: Theme.paddingLarge
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap
            }

            Label {
                //% "Latitude: "
                text: qsTrId("csd-la-latitude") + (satelliteLatitudeValid
                                                      //% "%0 °"
                                                    ? qsTrId("csd-la_value_degrees").arg(satellitePosition.latitude)
                                                      //% "unknown"
                                                    : qsTrId("csd-la-unknown"))
                x: Theme.paddingLarge
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap
            }
            Label {
                //% "Longitude: "
                text: qsTrId("csd-la-longitude") + (satelliteLongitudeValid
                                                     ? qsTrId("csd-la_value_degrees").arg(satellitePosition.longitude)
                                                       //% "unknown"
                                                     : qsTrId("csd-la-unknown"))
                x: Theme.paddingLarge
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap
            }
            Label {
                //% "Altitude: "
                text: qsTrId("csd-la-altitude") + (satelliteAltitudeValid
                                                      //% "%0 m"
                                                    ? qsTrId("csd-la_value_meters").arg(satellitePosition.altitude)
                                                      //% "unknown"
                                                    : qsTrId("csd-la-unknown"))
                x: Theme.paddingLarge
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap
            }
            Label {
                //% "Horizontal accuracy: "
                text: qsTrId("csd-la-horizontal_accuracy") + (satelliteHorizontalAccuracyValid
                                                               ? qsTrId("csd-la_value_meters").arg(satelliteHorizontalAccuracy)
                                                                 //% "unknown"
                                                               : qsTrId("csd-la-unknown"))
                x: Theme.paddingLarge
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap
            }
            Label {
                //% "Vertical accuracy: "
                text: qsTrId("csd-la-vertical_accuracy") + (satelliteVerticalAccuracyValid
                                                             ? qsTrId("csd-la_value_meters").arg(satelliteVerticalAccuracy)
                                                               //% "unknown"
                                                             : qsTrId("csd-la-unknown"))
                x: Theme.paddingLarge
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap
            }

            SectionHeader {
                //% "Assisted position"
                text: qsTrId("csd-he-assisted_position")
            }

            Label {
                //: %1 is the source of the assisted position, 'Last known position' or 'Non-satellite position'
                //% "Source: %1"
                text: qsTrId("csd-la-assist_source").arg(assistedSource)
                x: Theme.paddingLarge
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap
            }

            Item {
                height: Theme.paddingMedium
                width: parent.width
            }

            Label {
                //% "Time since assist fix: %0s"
                text: qsTrId("csd-la-time_since_assist_fix").arg(fixClock.secondsSinceAssistFix)
                x: Theme.paddingLarge
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap
            }

            Label {
                //% "Latitude: "
                text: qsTrId("csd-la-latitude") + (assistedLatitudeValid
                                                    ? qsTrId("csd-la_value_degrees").arg(assistedPosition.latitude)
                                                      //% "unknown"
                                                    : qsTrId("csd-la-unknown"))
                x: Theme.paddingLarge
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap
            }
            Label {
                //% "Longitude: "
                text: qsTrId("csd-la-longitude") + (assistedLongitudeValid
                                                     ? qsTrId("csd-la_value_degrees").arg(assistedPosition.longitude)
                                                       //% "unknown"
                                                     : qsTrId("csd-la-unknown"))
                x: Theme.paddingLarge
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap
            }

            SectionHeader {
                //% "Satellite status"
                text: qsTrId("csd-he-satellite_status")
            }

            Label {
                x: Theme.paddingLarge
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap

                color: gps.satelliteInfoAvailable ? "green" : "red"
                text: gps.satelliteInfoAvailable
                        //% "GPS satellite info available"
                      ? qsTrId("csd-la-gps_satellite_info_available")
                        //% "GPS satellite info unavailable"
                      : qsTrId("csd-la-gps_satellite_info_unavailable")
            }

            Label {
                x: Theme.paddingLarge
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap

                visible: gps.satelliteInfoError

                color: "red"

                //% "GPS satellite access error"
                text: qsTrId("csd-la-gps_satellite_info_error")
            }

            Item {
                height: Theme.paddingMedium
                width: parent.width
            }

            Label {
                //% "Satellites in use: %1"
                text: qsTrId("csd-la-satellites_in_use").arg(gps.satellitesInUse)
                x: Theme.paddingLarge
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap
            }

            Label {
                //% "Satellites in view: %1"
                text: qsTrId("csd-la-satellites_in_view").arg(gps.satellitesInView)
                x: Theme.paddingLarge
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap
            }

            Item {
                height: Theme.paddingMedium
                width: parent.width
            }

            Column {
                width: parent.width
                spacing: Theme.paddingSmall

                Repeater {
                    model: gps.satelliteInfo
                    delegate: SatelliteDelegate {
                        width: page.width
                    }
                }
            }
        }

        VerticalScrollDecorator { }
    }

    WallClock {
        id: fixClock

        property int secondsSinceSatelliteFix: (time - satelliteTimestamp) / 1000
        property int secondsSinceAssistFix: (time - assistTimestamp) / 1000

        updateFrequency: WallClock.Second
    }

    Gps { id: gps }
    LocationSettings { id: locationSettings }
}
