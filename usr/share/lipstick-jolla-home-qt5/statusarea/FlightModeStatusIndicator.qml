/****************************************************************************
**
** Copyright (c) 2013 - 2019 Jolla Ltd.
** Copyright (c) 2019 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0

Image {
    property alias offline: flightModeStatus.enabled
    source: "image://theme/icon-status-airplane-mode" + iconSuffix

    FlightModeStatus {
        id: flightModeStatus
    }

    opacity: flightModeStatus.enabled ? 1.0 : 0.0
}
