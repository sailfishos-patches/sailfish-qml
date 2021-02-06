/****************************************************************************
**
** Copyright (c) 2020 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************/

import QtQuick 2.6
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0

Icon {
    source: "image://theme/icon-status-do-not-disturb"
    visible: !!doNotDisturbConfig.value

    ConfigurationValue {
        id: doNotDisturbConfig
        defaultValue: false
        key: "/lipstick/do_not_disturb"
    }
}
