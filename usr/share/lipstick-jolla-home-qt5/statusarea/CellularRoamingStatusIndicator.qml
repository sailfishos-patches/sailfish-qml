/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Vesa Halttunen <vesa.halttunen@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.freedesktop.contextkit 1.0

Image {
    id: cellularRoamingStatusIndicator
    property bool updatesEnabled: true
    property string modemContext: "Cellular"
    source: "image://theme/icon-status-roaming" + iconSuffix

    visible: registrationStatus.value === "roam"

    ContextProperty {
        id: registrationStatus
        key: modemContext + ".RegistrationStatus"
    }

    onUpdatesEnabledChanged: {
        if (updatesEnabled) {
            registrationStatus.subscribe()
        } else {
            registrationStatus.unsubscribe()
        }
    }
}
