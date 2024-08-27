/*
 * Copyright (c) 2013 - 2019 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.1
import QtQuick.Window 2.1
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import Nemo.DBus 2.0
import Nemo.Notifications 1.0

SystemDialog {
    id: root

    //% "Calling is unavailable"
    title: qsTrId("voicecall-he-calling_unavailable")
    contentHeight: content.height

    Column {
        id: content
        width: parent.width

        SystemDialogHeader {
            id: header

            title: root.title
            //% "Reboot is required to recover calling, mobile data, and messaging"
            description: qsTrId("voicecall-la-reboot_required")
        }

        SystemDialogTextButton {
            width: header.width
            //% "Reboot"
            text: qsTrId("voicecall-la-reboot")
            onClicked: dsmeDbus.call("req_reboot", [])
        }
    }

    Notification {
        //% "Warnings"
        appName: qsTrId("voicecall-la-warnings")
        summary: root.title
        body: header.description
        category: "x-jolla.cellular.error"
        remoteActions: [ {
            "name": "default",
            "service": "com.jolla.voicecall.ui",
            "path": "/",
            "iface": "com.jolla.voicecall.ui",
            "method": "showCellularErrorDialog"
        }]
        Component.onCompleted: publish()
    }

    DBusInterface {
        id: dsmeDbus
        bus: DBusInterface.SystemBus
        service: "com.nokia.dsme"
        path: "/com/nokia/dsme/request"
        iface: "com.nokia.dsme.request"
    }
}
