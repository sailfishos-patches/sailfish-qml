/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.ofono 1.0
import ".."

CsdTestPage {

    property alias presentSimCount: modemManager.presentSimCount
    property alias availableModems: modemManager.availableModems
    property alias failTimerRunning: failTimer.running

    property var modemsEnabledAtStart
    property bool modemStateSaved

    function saveModemState() {
        if (!modemStateSaved && modemManager.valid) {
            modemStateSaved = true
            modemsEnabledAtStart = []
            for (var i = 0; i < modemManager.enabledModems.length; i++) {
                modemsEnabledAtStart[i] = modemManager.enabledModems[i]
            }
            modemManager.enabledModems = modemManager.availableModems
        }
    }

    function restoreModemState() {
        if (modemStateSaved) {
            modemStateSaved = false
            modemManager.enabledModems = modemsEnabledAtStart
        }
    }

    Component.onDestruction: restoreModemState()

    onStatusChanged: {
        if (status === PageStatus.Activating) {
            saveModemState()
        } else if (status === PageStatus.Inactive) {
            restoreModemState()
        }
    }

    OfonoModemManager {
        id: modemManager
        onValidChanged: {
            saveModemState()
            if (!presentSimCount) {
                failTimer.stop()
            }
        }
        onPresentSimCountChanged: {
            if (presentSimCount) {
                failTimer.restart()
            } else {
                failTimer.stop()
            }
        }
    }

    Timer {
        id: failTimer
        interval: 30000
        running: true
    }
}
