/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.1
import QtFeedback 5.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import org.nemomobile.lipstick 0.1
import Nemo.DBus 2.0
import org.nemomobile.notifications 1.0 as Nemo
import org.nemomobile.configuration 1.0
import com.jolla.lipstick 0.1

import "main"
import "switcher"

ApplicationWindow {
    id: window
    cover: undefined

    function desktopInstance() {
        return Desktop.instance
    }

    allowedOrientations: {
        var allowedOrientations = Screen.sizeCategory > Screen.Medium
                ? defaultAllowedOrientations
                : defaultAllowedOrientations & Orientation.PortraitMask

        if (Lipstick.compositor.alarmLayer.window
                    && (Lipstick.compositor.alarmLayer.window.orientation & allowedOrientations)) {
            return Lipstick.compositor.alarmLayer.window.orientation
        } else if (Lipstick.compositor.appLayer.window
                    && (Lipstick.compositor.appLayer.window.orientation & allowedOrientations)) {
            return Lipstick.compositor.appLayer.window.orientation
        } else {
            return _selectOrientation(allowedOrientations, Lipstick.compositor.screenOrientation)
        }
    }

    Binding {
        target: Lipstick.compositor
        property: "homeOrientation"
        value: allowedOrientations
    }

    Binding {
        when: window._dimScreen
        target: Lipstick.compositor.homeLayer.dimmer
        property: "dimmed"
        value: true
    }

    initialPage: Component { Page {
        id: desktop

        allowedOrientations: Orientation.All

        property alias switcher: switcher
        property bool coversVisible: Lipstick.compositor.switcherLayer.visible

        readonly property bool active: Lipstick.compositor.switcherLayer.active && Lipstick.compositor.systemInitComplete
        onActiveChanged: {
            if (!active) {
                hintTimer.stop()
                Lipstick.compositor.launcherHinting = false
                Lipstick.compositor.topMenuHinting = false
            } else if (switcher.count == 0
                        && Lipstick.compositor.previousWindow == Lipstick.compositor.lockScreenLayer.window) {
                hintTimer.start()

                if (Desktop.windowPromptPending) {
                    windowPrompt.call("showPendingPrompts", [])
                }
            }
        }

        onCoversVisibleChanged: {
            if (coversVisible) {
                CoverControl.status = Cover.Activating
                CoverControl.status = Cover.Active
            } else {
                CoverControl.status = Cover.Deactivating
                CoverControl.status = Cover.Inactive
            }
        }

        Component.onCompleted: {
            Desktop.instance = desktop
        }

        orientationTransitions: OrientationTransition {
            page: desktop
            applicationWindow: window
        }

        function setForceTopWindowProcessId(pid) {
            lockscreen.forceTopWindowProcessId = pid
        }

        Timer {
            id: hintTimer
            interval: 1000
            onTriggered: if (!Lipstick.compositor.topMenuHinting) Lipstick.compositor.launcherHinting = true
        }

        Switcher {
            id: switcher
            anchors.fill: parent
        }

        Binding {
            target: Lipstick.compositor.switcherLayer
            property: "contentY"
            value: switcher.contentY
        }

        Binding {
            target: Lipstick.compositor.switcherLayer
            property: "menuOpen"
            value: switcher.menuOpen
        }

        BluetoothSystemAgent {
            id: bluetoothSystemAgent
        }

        BluetoothObexSystemAgent {
            id: bluetoothObexSystemAgent
        }

        DBusAdaptor {
            service: "com.jolla.lipstick"
            path: "/bluetooth"
            iface: "com.jolla.lipstick"

            signal pairWithDevice(string address)
            signal replyToAgentRequest(int requestId, int error, string passkey)

            signal replyToObexAgentRequest(string transferPath, bool acceptFile)
            signal cancelTransfer(string transferPath)

            onPairWithDevice: bluetoothSystemAgent.pairWithDevice(address)
            onReplyToAgentRequest: bluetoothSystemAgent.replyToAgentRequest(requestId, error, passkey)

            onReplyToObexAgentRequest: bluetoothObexSystemAgent.replyToObexAgentRequest(transferPath, acceptFile)
            onCancelTransfer: bluetoothObexSystemAgent.cancelTransfer(transferPath)
        }

        VoicecallAgent {
            onDialNumber: voicecall.dial(number)
        }   

        DBusInterface {
            id: voicecall
            service: "com.jolla.voicecall.ui"
            path: "/" 
            iface: "com.jolla.voicecall.ui"

            function dial(number) {
                call('dial', number)
            }   
        }

        ShutterKeyHandler {
            // for now playing it safe and allowing only if device is properly unlocked
            enabled: !lipstickSettings.lockscreenVisible
            onPressAndHold: {
                vibraEffect.play()
                cameraInterface.call("showViewfinder", "")
            }
        }

        ThemeEffect {
            id: vibraEffect
            effect: ThemeEffect.PressWeak
        }

        DBusInterface {
            id: cameraInterface

            iface: "com.jolla.camera.ui"
            service: "com.jolla.camera"
            path: "/"
        }

        DBusInterface {
            id: windowPrompt
            service: "com.jolla.windowprompt"
            path: "/com/jolla/windowprompt"
            iface: "com.jolla.windowprompt"
        }
    } }
}
