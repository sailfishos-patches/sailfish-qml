/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.freedesktop.contextkit 1.0

Image {
    property bool updatesEnabled: true
    property alias offline: flightModeStatus.enabled
    source: "image://theme/icon-status-airplane-mode" + iconSuffix

    FlightModeStatus {
        id: flightModeStatus
        // System.InternetEnabled is MCE master radio switch
        key: "System.InternetEnabled"
    }

    opacity: flightModeStatus.enabled ? 1.0 : 0.0

    onUpdatesEnabledChanged: {
        if (updatesEnabled) {
            flightModeStatus.subscribe()
        } else {
            flightModeStatus.unsubscribe()
        }
    }
}
