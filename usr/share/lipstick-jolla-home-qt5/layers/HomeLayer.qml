/*
 * Copyright (c) 2014 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1
import Nemo.DBus 2.0
import org.nemomobile.configuration 1.0
import com.jolla.lipstick 0.1
import Sailfish.Lipstick 1.0
import "../compositor"
import "../main"
import "../statusarea"

Pannable {
    id: homescreen

    anchors.fill: parent

    property alias events: eventsLayer
    property alias switcher: switcherLayer
    property alias statusBar: statusBar
    property alias partnerspaces: partnerspaces

    readonly property Item window: currentItem.window
    readonly property bool active: currentItem.active
    readonly property bool wallpaperVisible: visible && !currentItem.opaque

    property PannableLayer lastActiveLayer

    property real statusMargin: Theme.paddingLarge

    property Item contentItem: currentItem.contentItem

    property real _minimizedScale: (Lipstick.compositor.topmostWindowHeight - (2 * statusMargin))
                / Lipstick.compositor.topmostWindowHeight
    Behavior on _minimizedScale {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }

    readonly property real _minimizeThreshold: width * (1.0 - _minimizedScale) / 2
    readonly property bool _transposed: Lipstick.compositor.topmostWindowAngle % 180 != 0

    function partnerLayerForWindow(window) {
        for (var layer = switcherLayer.rightItem; layer != eventsLayer; layer = layer.rightItem) {
            if (JollaSystemInfo.isWindowForLauncherItem(window, layer.launcherItem)) {
                return layer
            }
        }
        return null
    }

    function activatePartnerWindow(launcherItem, launch) {
        for (var layer = switcherLayer.rightItem; layer != eventsLayer; layer = layer.rightItem) {
            if (!layer.launcherItem || layer.launcherItem.exec != launcherItem.exec) {
                continue
            } else if (!layer.window.window && launch) {
                layer.start()
            }

            layer.maximized = true
            Lipstick.compositor.goToHome(layer, true)
            return true
        }
    }

    function partnerWindowRaised(window) {
        if (Lipstick.compositor.visible) {
            Lipstick.compositor.goToHome(window.layerItem, false)
            window.layerItem.maximized = true
        }
    }

    function partnerWindowLowered(window) {
    }

    function partnerWindowRemoved(window) {
        window.layerItem.maximized = false
    }

    function _findNextLayer(launcherItem) {
        var index = partnerspaces.indexOf(launcherItem)
        for (var layer = switcherLayer.rightItem; layer != eventsLayer; layer = layer.rightItem) {
            if (layer.launcherItem && index < partnerspaces.indexOf(layer.launcherItem)) {
                return layer
            }
        }
        return eventsLayer
    }

    Component.onCompleted: {
        systemdManager.typedCall(
                    "GetUnit",
                    { 'type': "s", 'value': "aliendalvik.service" },
                    function (path) {
                        alienDalvikUnit.path = path
                    }, function() {
                        // Swallow warning if alien dalvik is not installed.
                    })
    }

    objectName: "homeLayer"

    orientation: Lipstick.compositor.topmostWindowOrientation
    pan: !Lipstick.compositor.deviceIsLocked && !Lipstick.compositor.topMenuLayer.active

    currentItem: switcherLayer

    peekFilter {
        leftEnabled: Lipstick.compositor.systemInitComplete
        rightEnabled: Lipstick.compositor.systemInitComplete
        threshold: homescreen._minimizeThreshold
    }

    dragArea {
        enabled: !currentItem.maximized && Lipstick.compositor.systemInitComplete
        opacity: Math.min(1.0, Theme.opacityLow + (1.0 - Theme.opacityLow)*Math.pow((1.0 - Math.min(homescreen.overshoot, Theme.itemSizeExtraLarge*2)/(Theme.itemSizeExtraLarge*2)), 1.5))
    }

    switchThreshold: dragArea.drag.threshold * 1.5

    onCurrentItemChanged: {
        if (active) {
            Lipstick.compositor.setCurrentWindow(currentItem.window)
        }
    }

    onPanningChanged: {
        if (panning) {
            Lipstick.compositor.launcherHinting = false
            Lipstick.compositor.topMenuHinting = false
        }
    }

    PageBusyIndicator {
        y: parent.height/4
        running: !Lipstick.compositor.systemInitComplete
    }

    Item {
        id: statusContainer

        anchors.centerIn: parent

        rotation: Lipstick.compositor.topmostWindowAngle
        Behavior on rotation {
            SequentialAnimation {
                FadeAnimation { target: statusContainer; to: 0.0 }
                PropertyAction { property: "rotation" }
                FadeAnimation { target: statusContainer; to: 1.0 }
            }
        }

        width: rotation % 180 == 0
                    ? Lipstick.compositor.width
                    : Lipstick.compositor.height
        height: rotation % 180 == 0
                    ? Lipstick.compositor.height
                    : Lipstick.compositor.width
        z: active ? 0 : -1000

        StatusBar {
            id: statusBar

            property real opacityFromY: Math.max(0, (height + y*1.5)/height)

            backgroundVisible: true
            y: -currentItem.statusOffset * (1.0-homescreen.progress) - (alternateItem ? alternateItem.statusOffset * homescreen.progress : 0)
            updatesEnabled: Lipstick.compositor.homeActive || (Lipstick.compositor.peekingLayer.exposed && !Lipstick.compositor.peekingLayer.opaque)
            opacity: Math.min(1.0, opacityFromY, currentItem.statusOpacity)
        }
    }

    pannableItems: [
        EventsLayer {
            id: eventsLayer

            objectName: "eventsLayer"

            leftItem: switcherLayer
            rightItem: switcherLayer

            width: homescreen.width
            height: homescreen.height

            visible: false

            anchors { leftMargin: leftItem.minimizeMargin }
        },
        SwitcherLayer {
            id: switcherLayer

            readonly property real inactiveScale: Screen.sizeCategory >= Screen.Large ? 0.90 : 0.83
            readonly property bool moving: homescreen.moving
                        || (Desktop.instance && Desktop.instance.switcher.moving)
            property bool inhibitScale
            property real inhibitedScale
            onMovingChanged: {
                if (moving) {
                    inhibitedScale = scale
                }
                inhibitScale = moving
            }

            objectName: "switcherLayer"

            leftItem:  eventsLayer
            rightItem: eventsLayer

            width: homescreen.width
            height: homescreen.height

            scale: {
                if (inhibitScale) {
                    return inhibitedScale
                } else if (Desktop.instance && Desktop.instance.switcher.appShowInProgress) {
                    return inactiveScale
                } else if (Lipstick.compositor.launcherLayer.exposed) {
                    return 1 - ((1 - inactiveScale) * Lipstick.compositor.launcherLayer.exposure)
                } else if (Lipstick.compositor.topMenuLayer.exposed) {
                    return 1 - ((1 - inactiveScale) * Lipstick.compositor.topMenuLayer.exposure)
                } else if (homescreen.active || Lipstick.compositor.topmostIsDialog) {
                    return 1
                } else {
                    return inactiveScale
                }
            }
            Behavior on scale {
                enabled: switcherLayer.visible
                NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
            }

            anchors { rightMargin: -rightItem.minimizeMargin }
        }
    ]

    PartnerspaceModel {
        id: partnerspaces

        includeAmbience: true

        onItemAdded: {
            var insertBefore = homescreen._findNextLayer(item)
            var insertAfter = insertBefore.leftItem
            insertBefore.leftItem
                    = insertAfter.rightItem
                    = partnerComponent.createObject(pannableParent,  {
                'launcherItem': item,
                'leftItem': insertAfter,
                'rightItem': insertBefore
            })
        }

        onItemRemoved: {
            var apkdPackage = item.readValue("X-apkd-packageName")

            for (var layer = switcherLayer.rightItem; layer != eventsLayer; layer = layer.rightItem) {
                if (layer.launcherItem == item) {
                    function cleanup() {
                        var left = layer.leftItem
                        var right = layer.rightItem

                        left.rightItem = right
                        right.leftItem = left

                        if (layer.window.window) {
                            layer.window.window.userData = null
                            layer.window.window.surface.destroySurface()
                        }
                        layer.destroy()

                        if (apkdPackage != "") {
                            apkConfiguration.call("forceStopApp", [ apkdPackage ])
                        }
                    }

                    if (layer.isCurrentItem) {
                        layer.cleanup = cleanup
                        homescreen.setCurrentItem(switcherLayer, homescreen.visible)
                    } else if (layer.isAlternateItem) {
                        layer.cleanup = cleanup
                    } else {
                        cleanup()
                    }
                    return
                }
            }
        }

        onRowsMoved: {
            var count = end - start + 1
            var index = row > start ? row - count : row

            var i = count
            var firstMoved = eventsLayer
            var lastMoved = eventsLayer
            for (var layer = switcherLayer.rightItem; layer != eventsLayer; layer = layer.rightItem) {
                for (i = 0; i < count; ++i) {
                    if (layer.launcherItem == partnerspaces.get(index + i)) {
                        firstMoved = layer
                        lastMoved = layer
                        layer = eventsLayer.leftItem
                        break;
                    }
                }
            }

            for (++i; i < count && lastMoved.rightItem != eventsLayer; ++i) {
                var launcherItem = partnerspaces.get(index + i)
                if (lastMoved.rightItem.launcherItem == launcherItem) {
                    lastMoved = lastMoved.rightItem
                }
            }

            if (firstMoved != eventsLayer) {
                firstMoved.leftItem.rightItem = lastMoved.rightItem
                lastMoved.rightItem.leftItem = firstMoved.leftItem

                var insertBefore = _findNextLayer(lastMoved.launcherItem)
                var insertAfter = insertBefore.leftItem

                firstMoved.leftItem = insertAfter
                insertAfter.rightItem = firstMoved
                lastMoved.rightItem = insertBefore
                insertBefore.leftItem = lastMoved
            }
        }
    }

    Component {
        id: partnerComponent

        PartnerLayer {
            id: partnerLayer

            launcherItem: model.object

            width: homescreen.width
            height: homescreen.height

            minimizedScale: homescreen._minimizedScale
            minimizeThreshold: homescreen._minimizeThreshold

            pending: true
            moving: homescreen.moving
            panning: homescreen.panning
            peeking: peekFilter.leftActive || peekFilter.rightActive
            peekProgress: peekFilter.progress

            visible: false

            isActiveInHome: homescreen.lastActiveLayer == partnerLayer
            launcherActive: launcherItem && (launcherItem.readValue("X-apkd-apkfile") == ""
                        || alienDalvikUnit.activeState == "active")

            anchors { leftMargin: -partnerLayer.minimizeMargin + leftItem.minimizeMargin }
            anchors { rightMargin: partnerLayer.minimizeMargin - rightItem.minimizeMargin }
        }
    }

    DBusInterface {
        id: apkConfiguration

        bus: DBus.SystemBus
        service: "com.myriadgroup.alien.settings"
        path: "/com/myriadgroup/alien/settings"
        iface: "com.myriadgroup.alien.settings"
    }

    DBusInterface {
        id: systemdManager

        bus: DBus.SystemBus
        service: "org.freedesktop.systemd1"
        iface: "org.freedesktop.systemd1.Manager"
        path: "/org/freedesktop/systemd1"
    }

    DBusInterface {
        id: alienDalvikUnit

        bus: DBus.SystemBus
        service: "org.freedesktop.systemd1"
        iface: "org.freedesktop.systemd1.Unit"
        propertiesEnabled: true

        property string activeState
    }
}
