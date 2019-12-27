/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.freedesktop.contextkit 1.0
import Nemo.DBus 2.0
import org.nemomobile.lipstick 0.1
import com.jolla.lipstick 0.1

BackgroundItem
{
    id: root
    property int callCount: Number(cellular1Calls.value) + Number(cellular2Calls.value)
    property bool ongoingCall: callCount > 0

    enabled: ongoingCall && voicecallPingTimer.ok
    height: Theme.itemSizeLarge
    width: parent.width

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.paddingLarge
        Image {
            id: icon
            source: "image://theme/icon-launcher-phone"
            opacity: ongoingCall ? (voicecallPingTimer.ok ? 1.0 : Theme.opacityLow) : 0.0
            Behavior on opacity { FadeAnimation {} }
        }
        Label {
            anchors.verticalCenter: icon.verticalCenter
            //% "%n ongoing call(s)"
            text: qsTrId("lipstick-jolla-home-la-ongoing-calls", callCount)
            color: highlighted ? Theme.highlightColor : Theme.primaryColor
            opacity: ongoingCall ? 1.0 : 0.0
            Behavior on opacity { FadeAnimation {} }
        }
    }

    onClicked: {
        // ongoing call icon in lock screen was clicked
        // show call ui
        voicecallIf.call("showOngoing", undefined)
    }

    Timer {
        id: voicecallPingTimer
        property bool ok
        property bool replyPending
        running: ongoingCall
        interval: 5000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (replyPending) {
                ok = false
            } else {
                replyPending = true
                voicecallPeerIf.typedCall("Ping", undefined,
                                          function() { ok = true; replyPending = false },
                                          function() { ok = false;replyPending = false })
            }
        }
        onRunningChanged: if (running) ok = false
    }

    BusyIndicator {
        x: row.x + (icon.width-width)/2
        anchors.verticalCenter: parent.verticalCenter
        running: ongoingCall && !voicecallPingTimer.ok
    }

    ContextProperty {
        id: cellular1Calls
        key: Desktop.cellularContext(1) + ".CallCount"
    }
    ContextProperty {
        id: cellular2Calls
        key: Desktop.cellularContext(2) + ".CallCount"
    }

    DBusInterface {
        id: voicecallIf
        service: "com.jolla.voicecall.ui"
        path: "/"
        iface: "com.jolla.voicecall.ui"
    }
    DBusInterface {
        id: voicecallPeerIf
        service: "com.jolla.voicecall.ui"
        path: "/"
        iface: "org.freedesktop.DBus.Peer"
    }
}

