/****************************************************************************************
**
** Copyright (c) 2013 - 2021 Jolla Ltd.
** Copyright (c) 2021 Open Mobile Platform LLC
** All rights reserved.
**
** License: Proprietary.
**
****************************************************************************************/
import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.DBus 2.0

Item {
    property var shareAction

    Component.onCompleted: {
        settingsApp.call("share", [shareAction.toConfiguration()])
        shareAction.done()
    }

    DBusInterface {
        id: settingsApp

        service: "com.jolla.settings"
        path: "/share_signing_keys"
        iface: "org.sailfishos.share"
    }
}
