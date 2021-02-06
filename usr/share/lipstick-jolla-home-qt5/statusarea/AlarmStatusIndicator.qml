/****************************************************************************
**
** Copyright (C) 2013 - 2019 Jolla Ltd.
** Copyright (C) 2019 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************/

import QtQuick 2.6
import com.jolla.lipstick 0.1
import Sailfish.Silica 1.0

Icon {
    source: "image://theme/icon-status-alarm" + iconSuffix
    visible: Desktop.timedStatus.alarmPresent
    height: visible ? implicitHeight : 0
}
