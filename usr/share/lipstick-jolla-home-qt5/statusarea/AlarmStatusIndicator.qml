/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import org.freedesktop.contextkit 1.0

Image {
    source: "image://theme/icon-status-alarm" + iconSuffix
    visible: alarmContextProperty.value !== undefined && alarmContextProperty.value
    height: visible ? implicitHeight : 0

    ContextProperty {
        id: alarmContextProperty
        key: "Alarm.Present"
    }
}
