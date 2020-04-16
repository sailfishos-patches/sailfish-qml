/****************************************************************************
**
** Copyright (c) 2013 - 2019 Jolla Ltd.
** Copyright (c) 2019 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************/

import QtQml 2.2
import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import MeeGo.QOfono 0.2
import Nemo.DBus 2.0
import org.nemomobile.lipstick 0.1
import com.jolla.lipstick 0.1

BackgroundItem
{
    id: root
    property int callCount
    property bool ongoingCall: callCount > 0

    function _refreshCallCount() {
        var _callCount = 0
        for (var i = 0; i < voiceCallManagers.count; ++i) {
            _callCount += voiceCallManagers.objectAt(i).calls.length
        }
        callCount = _callCount
    }

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

    Instantiator {
        id: voiceCallManagers

        model: Desktop.simManager.availableModems

        delegate: OfonoVoiceCallManager {
            id: callManager

            property var calls: []

            modemPath: modelData

            onCallAdded: {
                callManager.calls.push(call)
                root._refreshCallCount()
            }
            onCallRemoved: {
                callManager.calls.pop(callManager.calls.indexOf(call))
                root._refreshCallCount()
            }
        }
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

