/*
 * Copyright (c) 2015 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1
import com.jolla.lipstick 0.1
import org.nemomobile.devicelock 1.0
import Nemo.Configuration 1.0
import "../backgrounds"

Layer {
    id: lockScreenLayer

    property bool screenIsLocked
    property bool deviceIsLocked
    property bool pendingPinQuery
    property bool lockSuppressedByPeek
    property bool showingLockCodeEntry
    property real notificationOpacity: showNotifications ? (lipstickSettings.lowPowerMode ? Theme.opacityOverlay : 1.0) : 0.0

    property string unlockReason
    property alias background: background
    property alias dimmer: background
    property alias vignette: background.vignette

    readonly property bool locked: screenIsLocked || deviceIsLocked || Lipstick.compositor.cameraLayer.active

    // Text color of items that are shown in low power mode
    property color textColor: lipstickSettings.lowPowerMode ? Theme.highlightColor : Theme.primaryColor

    // Controlled by LockScreen.
    property bool showNotifications

    readonly property bool lockScreenEventsEnabled: lockScreenEvents && Desktop.deviceLockState >= DeviceLock.Locked
    readonly property bool lockScreenEvents: Desktop.settings.lock_screen_events && Desktop.settings.lock_screen_events_allowed && !!eventsContainer
    property Item eventsContainer

    signal cacheWindow(Item window)

    objectName: "lockScreenLayer"

    enabled: active
             && !Lipstick.compositor.topMenuLayer.active    // don't pan lockscreen views when top menu is visible

    onLockedChanged: {
        if (!locked && !peekingAtHome) {
            close()
        }
    }

    onAboutToClose: cacheWindow(window)

    underlayItem.children: LockscreenBackground {
        id: background

        width: lockScreenLayer.width
        height: lockScreenLayer.height
    }
}
