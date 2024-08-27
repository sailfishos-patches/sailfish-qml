/*
 * Copyright (c) 2021 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Nemo.DBus 2.0
import Nemo.FileManager 1.0

DBusInterface {
    id: copyService

    bus: DBus.SystemBus
    service: "org.sailfishos.HomeCopyService"
    path: "/org/sailfishos/HomeCopyService"
    iface: "org.sailfishos.HomeCopyService"
    signalsEnabled: true
    // Prevents automatic introspection but simplifies the code otherwise
    watchServiceStatus: true

    // This introspects the interface. Thus, starting the dbus service.
    readonly property DBusInterface introspectAtStart: DBusInterface {
        bus: DBus.SystemBus
        service: copyService.service
        path: copyService.path
        iface: "org.freedesktop.DBus.Introspectable"
        Component.onCompleted: call("Introspect")
    }


    function setCopyDev(dev) {
        call("setCopyDevice", [dev])
    }

    function copyHome(dev) {
        setCopyDev(dev)
        call("copyHome", [])
    }

    signal copied(bool success)

    function copyDone(value) {
        console.log("SD copied:", value)
        copied(value)
    }

}
