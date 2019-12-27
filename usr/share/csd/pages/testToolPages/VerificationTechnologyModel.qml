/*
 * Copyright (c) 2015 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQml 2.2
import MeeGo.Connman 0.2
import Sailfish.Policy 1.0

TechnologyModel {
    id: techModel
    property bool wasInitiallyPowered
    property bool testFinished

    signal finished(bool success)

    function reset() {
        testFinished = false
    }

    function initTestCase() {
        initIfAvailable()
    }

    function restoreInitialPoweredState() {
        if ((techModel.name == "gps" && !gpsPolicy.value)
                || (techModel.name == "wifi" && !wlanPolicy.value)) {
            return // policy prevents changing the power state of these technologies.
        }
        if (powered != wasInitiallyPowered) {
            powered = wasInitiallyPowered
        }
    }

    function done(success) {
        restoreInitialPoweredState()
        finished(success)
        testFinished = true
    }

    function initIfAvailable() {
        if ((techModel.name == "gps" && !gpsPolicy.value)
                || (techModel.name == "wifi" && !wlanPolicy.value)) {
            return // policy prevents changing the power state of these technologies.
        }
        if (available) {
            wasInitiallyPowered = powered
            powered = true
        }
    }

    onAvailableChanged: {
        initIfAvailable()
        if (!available) {
            done(false)
        }
    }

    Component.onDestruction: restoreInitialPoweredState()

    property PolicyValue gpsPolicy: PolicyValue {
        policyType: PolicyValue.LocationSettingsEnabled
    }

    property PolicyValue wlanPolicy: PolicyValue {
        id: wlanPolicy
        policyType: PolicyValue.WlanToggleEnabled
    }
}
