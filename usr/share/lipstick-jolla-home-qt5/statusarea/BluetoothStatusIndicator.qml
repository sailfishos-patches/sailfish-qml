/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0

Image {
    source: 'image://theme/icon-status-bluetooth' + (bluetooth.connected ? '-connected' : '') + iconSuffix
    opacity: bluetooth.connected || bluetooth.enabled ? 1.0 : 0.0
    Behavior on opacity { FadeAnimation {} }

    BluetoothStatus {
        id: bluetooth
    }
}
