/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.2
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1
import Nemo.DBus 2.0

Item {
    id: root

    property QtObject compositor

    function dumpTopmostWindow() {
        console.log("Topmost window:", compositor.topmostWindow)
        for (var i in compositor.topmostWindow) {
            var value = compositor.topmostWindow[i]
            if (!value || value && !value.toString().match(/function()/g)) {
                console.log("          - wrapper ", i, ": " + compositor.topmostWindow[i])
            }
        }

        if (compositor.topmostWindow.window) {
            console.log("          - wrapper window windowId: " + compositor.topmostWindow.window.windowId)
            console.log("          - wrapper window isInProcess: " + compositor.topmostWindow.window.isInProcess)
            console.log("          - wrapper window delayRemove: " + compositor.topmostWindow.window.delayRemove)
            console.log("          - wrapper window category: " + compositor.topmostWindow.window.category)
            console.log("          - wrapper window title: " + compositor.topmostWindow.window.title)
            console.log("          - wrapper window processId: " + compositor.topmostWindow.window.processId)
            console.log("          - wrapper window mouseRegionBounds: " + compositor.topmostWindow.window.mouseRegionBounds)
            console.log("          - wrapper window focusOnTouch: " + compositor.topmostWindow.window.focusOnTouch)
        }

        console.log("Active windows: " + compositor.windowCount)
        console.log("Retained windows: " + compositor.ghostWindowCount)
        console.log("Home visible: " + compositor.homeVisible)
        console.log("Device is locked: " + compositor.deviceIsLocked)
        console.log("Screen is locked: " + compositor.screenIsLocked)
    }

    Rectangle {
        id: debugArea

        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4

        x: 4; width: parent.width - 8; height: infoColumn.height + 14
        radius: 15
        border.color: "white"
        color: "#B0000000"

        opacity: enabled ? 1.0 : 0.0

        Behavior on opacity { FadeAnimator {} }

        Column {
            id: infoColumn
            x: 15; y: 5; width: parent.width
            Text { color: "white"; text: "Active windows: " + compositor.windowCount }
            Text { color: "white"; text: "Retained windows: " + compositor.ghostWindowCount }
            Text { color: "white"; text: "Home visible: " + compositor.homeVisible }
            Text { color: "white"; text: "Topmost window: " + compositor.topmostWindow.window.windowId }
            Text { color: "white"; text: "Topmost window title: " + compositor.topmostWindow.window.title }
        }

        DBusAdaptor {
            service: "org.nemomobile.compositor.debug"
            path: "/debug"
            iface: "org.nemomobile.compositor.debug"

            function dump() {
                root.dumpTopmostWindow()
            }
        }

        DebugButton {
            anchors {
                topMargin: 10
                right: parent.right
                rightMargin: 10
            }
            text: "Expose"
            onClicked: windows.active = true
        }

        DebugButton {
            anchors {
                bottom: parent.bottom
                bottomMargin: 10
                right: parent.right
                rightMargin: 10
            }
            text: "Dump"
            onClicked: root.dumpTopmostWindow()
        }
    }

    MouseArea {
        width: 30
        height: 30
        propagateComposedEvents: true
        anchors {
            left: debugArea.left
            bottom: debugArea.bottom
        }
        onClicked: {
            debugArea.enabled = !debugArea.enabled
            mouse.accepted = false
        }
    }

    Loader {
        id: windows
        anchors.fill: parent
        active: false
        sourceComponent: Rectangle {
            anchors.fill: parent
            color: "white"
            ListView {
                id: view
                anchors.fill: parent
                model: WindowModel {}
                delegate: Item {
                    width: view.width
                    height: 220
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: 17
                        text: model.window + ", \"" + model.title + "\""
                    }
                    Rectangle {
                        x: 50; y: 20; width: 154; height: 194
                        color: "black"
                        WindowPixmapItem {
                            width: 150; height: 190
                            anchors.centerIn: parent
                            windowId: model.window
                        }
                    }
                    Item { 
                        x: view.width - 50 - width; y: 20; width: 154; height: 194

                        Rectangle {
                            id: mr
                            property QtObject window: Lipstick.compositor.windowForId(model.window)
                            x: window.mouseRegionBounds.x * (parent.width / window.width)
                            y: window.mouseRegionBounds.y * (parent.height / window.height)
                            width: window.mouseRegionBounds.width * (parent.width / window.width)
                            height: window.mouseRegionBounds.height * (parent.height / window.height)
                            color: "lightsteelblue"
                        }

                        Text {
                            anchors.centerIn: parent
                            font.pixelSize: 17
                            text: mr.window.mouseRegionBounds.x + "," + mr.window.mouseRegionBounds.y +
                                  "-" + mr.window.mouseRegionBounds.width + "x" +
                                  mr.window.mouseRegionBounds.height
                        }
                    }
                }
            }

            Rectangle {
                width: 70; height: 30
                color: "#d0b0c4de"
                radius: 5
                border.color: "black"
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                Text { anchors.centerIn: parent; font.pixelSize: 20; text: "Close" }
                MouseArea {
                    anchors.fill: parent
                    onClicked: windows.active = false
                }
            }
        }
    }
}
