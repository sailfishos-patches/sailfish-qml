/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import org.nemomobile.lipstick 0.1
import Nemo.DBus 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import com.jolla.lipstick 0.1
import "../systemwindow"

SystemWindow {
    id: root

    property bool restarting
    property int warningType
    readonly property bool isRemovalWarning: warningType == PinQueryAgent.RemovalWarning

    signal done()

    function restart() {
        root.shouldBeVisible = false
        root.restarting = true
        dsmeDbus.call("req_reboot", [])
    }

    contentHeight: content.height

    onHidden: done()

    SystemDialogLayout {
        contentHeight: content.height
        onDismiss: root.shouldBeVisible = false

        Column {
            id: content
            width: parent.width

            SystemDialogHeader {
                title: isRemovalWarning
                          //% "SIM card removed"
                        ? qsTrId("lipstick-jolla-home-bt-sim_card_removed")
                          //% "SIM card inserted"
                        : qsTrId("lipstick-jolla-home-bt-sim_card_inserted")

                description: isRemovalWarning
                          //: The SIM has been removed. Indicate that if a SIM is inserted a reboot will be required.
                          //% "A restart is required to activate an inserted SIM."
                        ? qsTrId("lipstick-jolla-home-la-sim_removal_restart")
                          //% "Without restarting the device, SIM card might not work reliably."
                        : qsTrId("lipstick-jolla-home-la-sim_reboot")
                topPadding: transpose ? Theme.paddingLarge : 2*Theme.paddingLarge
            }

            SystemDialogIconButton {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Theme.itemSizeHuge*1.5
                iconSource: (Screen.sizeCategory >= Screen.Large) ? (isRemovalWarning ? "image://theme/icon-l-acknowledge" : "image://theme/icon-l-reboot")
                                                                  : (isRemovalWarning ? "image://theme/icon-m-acknowledge" : "image://theme/icon-m-reboot")
                text: isRemovalWarning
                          //% "Got it"
                        ? qsTrId("lipstick-jolla-home-bt-ok")
                          //% "Restart now"
                        : qsTrId("lipstick-jolla-home-bt-restart_now")
                onClicked: {
                    if (isRemovalWarning) {
                        root.shouldBeVisible = false
                    } else {
                        root.restart()
                    }
                }
            }
        }
    }

    DBusInterface {
        id: dsmeDbus
        bus: DBus.SystemBus
        service: "com.nokia.dsme"
        path: "/com/nokia/dsme/request"
        iface: "com.nokia.dsme.request"
    }
}
