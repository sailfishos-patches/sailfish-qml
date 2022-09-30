/****************************************************************************************
**
** Copyright (c) 2021 Jolla Ltd.
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
        shareAction.replaceFileResourcesWithFileDescriptors()
        sms.call("shareSms", [shareAction.toConfiguration()])
        shareAction.done()
    }

    DBusInterface {
        id: sms

        service: "org.sailfishos.Messages"
        path: "/share"
        iface: "org.sailfishos.share"
    }
}
