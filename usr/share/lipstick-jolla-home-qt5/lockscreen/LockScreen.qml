/****************************************************************************
**
** Copyright (C) 2015 Jolla Ltd.
** Contact: Raine Makelainen <raine.makelainen@jolla.com>
**
****************************************************************************/

import QtQuick 2.0
import org.nemomobile.lipstick 0.1
import org.nemomobile.configuration 1.0
import org.nemomobile.devicelock 1.0
import org.nemomobile.ngf 1.0
import Sailfish.Silica 1.0
import Sailfish.Ambience 1.0
import com.jolla.lipstick 0.1
import Sailfish.Lipstick 1.0
import org.nemomobile.notifications 1.0
import "../compositor"
import "../main"
import "../statusarea"
import "../sim"

ApplicationWindow {
    id: window

    cover: undefined
    _clippingItem.opacity: 1.0
    allowedOrientations: Lipstick.compositor.homeOrientation

    initialPage: Component {
        Page {
            id: lockScreenPage
            allowedOrientations: Orientation.All
            property bool displayOnFromLowPowerMode
            readonly property bool interactionExpected: !visible || wallpaperDimmer.relativeDim
                                                        || lockScreen.pinQueryPannable || Lipstick.compositor.topMenuLayer.exposed
                                                        || Lipstick.compositor.launcherLayer.exposed
            property bool displayIsOn: true

            onInteractionExpectedChanged: lipstickSettings.setInteractionExpected(interactionExpected)

            Latch {
                id: systemStarted

                value: (!startupWizardExpiry.running || Lipstick.compositor.appLayer.opaque)
                            && (PinQueryAgent.simStatus != PinQueryAgent.SimUndefined || PinQueryAgent.simPinCompleted)
            }

            Timer {
                // Don't block the UI forever if the startup wizard fails to launch.
                id: startupWizardExpiry

                running: Desktop.startupWizardRunning
                interval: 30000
            }

            WallpaperDimmer {
                id: wallpaperDimmer

                anchors.fill: parent

                offset: Math.abs(deviceLockContainer.offset)
                relativeDim: deviceLockContainer.exposed
            }

            Vignette {
                id: vignette

                active: false
                anchors.fill: lockScreenPage
                openRadius: 0.75
                softness: 0.7
                animated: lipstickSettings.blankingPolicy == "default"

                onActiveChanged: {
                    if (active) {
                        lockItem.hintEdges()
                    }
                }

                onOpenedChanged: {
                    if (opened) {
                        lockScreenPage.displayOnFromLowPowerMode = false
                        if (Lipstick.compositor.dialogBlurSource) {
                            Lipstick.compositor.dialogBlurSource.update()
                        }
                    }
                }
            }

            Connections {
                target: Lipstick.compositor
                onDisplayOff: {
                    displayIsOn = false
                    lockScreen.activate(false)
                    if (lockScreen.lowPowerMode) {
                        lockItem.leftIndicator.hinting = false
                        lockItem.rightIndicator.hinting = false
                    }
                }

                onDisplayOn: {
                    displayIsOn = true
                    if (!systemStarted.value) {
                        return;
                    }

                    vignette.active = true
                    lockScreen.displayOn = true
                }

                // Updates enabled
                onDisplayAboutToBeOn: {
                    if (!systemStarted.value) {
                        return;
                    }

                    lockScreenPage.displayOnFromLowPowerMode = lockScreen.lowPowerMode

                    if (PinQueryAgent.simStatus != PinQueryAgent.NoSim && !PinQueryAgent.simPinCompleted) {
                        lockScreen.nextPannableItem(false, false)
                    } else {
                        lockScreen.reset()
                        if (Lipstick.compositor.showDeviceLock && deviceLockItem.locked) {
                            lockScreen.nextPannableItem(false, true)
                        }
                    }

                    if (PinQueryAgent.simPinCompleted && lockScreen.pinQueryPannable) {
                        lockScreen.pinQueryPannable.destroy()
                    }

                    lockScreen.open(false)
                }

                // Updates disabled
                onDisplayAboutToBeOff: {
                    lockScreen.displayOn = false
                    if (!lockScreen.lowPowerMode) {
                        lockItem.reset()
                    }
                }

                onUnlock: {
                    if (!displayIsOn) {
                        // Ignore unlock requests while display is not powered up
                    } else if (Desktop.startupWizardRunning) {
                        // Ignore unlock requests while the startup wizard is running
                    } else if (deviceLockItem.locked || lockScreen.needPinQuery) {
                        // Opening application from LockScreen pulley menu.
                        lockScreen.nextPannableItem(deviceLockItem.ready, true)
                        Lipstick.compositor.setCurrentWindow(Lipstick.compositor.lockScreenLayer.window)
                    } else {
                        lipstickSettings.lockscreenVisible = false
                    }
                }

                onPeekGestureStarted: {
                    if (deviceLockItem.locked || lockScreen.needPinQuery) {
                        // Peeking while device is locked.
                        lockScreen.nextPannableItem(!Lipstick.compositor.peekingLayer.childrenOpaque, true, direction)
                    }
                }

                onPeekGestureReset: {
                    lockContainer.interactive = true
                    lockScreen.setCurrentItem(lockContainer, !Lipstick.compositor.peekingLayer.childrenOpaque)
                }
            }

            Connections {
                target: lipstickSettings
                onLockscreenVisibleChanged: {
                    if (lipstickSettings.lockscreenVisible && !Lipstick.compositor.cameraLayer.active) {
                        Lipstick.compositor.setCurrentWindow(Lipstick.compositor.lockScreenLayer.window)
                    } else if (!lipstickSettings.lockscreenVisible && Desktop.deviceLockState == DeviceLock.Locked) {
                        Lipstick.compositor.showDeviceLock = true
                    }
                }
            }

            StatusBar {
                id: statusBar
                y: lockItem.contentY
                lockscreenMode: true
                updatesEnabled: lockScreen.locked
                color: lockScreen.textColor
                opacity: systemStarted.value && vignette.opened && Desktop.deviceLockState <= DeviceLock.Locked
                         ? (deviceLockContainer.isCurrentItem ? deviceLockItem.opacity : lockItem.clock.transitionOpacity)
                         : 0.0
                z: 1
            }

            PageBusyIndicator {
                id: waitingSystemStart
                running: !systemStarted.value

                onRunningChanged: {
                    if (!running) {
                        if (lockScreen.needPinQuery) {
                            lockScreen.nextPannableItem(false, false)
                        }

                        vignette.active = true
                        lockScreen.displayOn = true
                    }
                }
            }

            Binding {
                target: Lipstick.compositor.lockScreenLayer
                property: "showNotifications"
                // Show notifications only on lock container given that lockscreen is not moving
                // and device lock is unlocked or locked, so no notifications
                // in ManagerLockout, TemporaryLockout, PermanentLockout, or Undefined
                value: (Desktop.deviceLockState == DeviceLock.Unlocked || Desktop.deviceLockState == DeviceLock.Locked)
                        && (Lipstick.compositor.lockScreenLayer.opaque && systemStarted.value)
                        && ((vignette.opened || lockScreenPage.displayOnFromLowPowerMode)
                           && lockContainer.isCurrentItem && !lockScreen.moving
                           || lockScreen.lowPowerMode)
            }

            Binding {
                target: Lipstick.compositor.lockScreenLayer
                property: "pendingPinQuery"
                value: lockScreen.needPinQuery
            }

            Connections {
                target: PinQueryAgent
                onShowSimPinInput: {
                    if (Desktop.startupWizardRunning) {
                        // Ignore pin query requests until startup wizard completes
                        PinQueryAgent.simPinCompleted = true
                    } else {
                        Lipstick.compositor.showApplicationOverLockscreen = false
                        lockScreen.activate(true)
                        lockScreen.open(true)
                        // If device was locked when SIM card inserted,
                        // nextPannableItem sets device lock as current item.
                        lockScreen.nextPannableItem(false, false)
                        lipstickSettings.lockScreen(true)
                    }
                }
                onSimPinRequiredChanged: {
                    if (!PinQueryAgent.simPinRequired) {
                        deviceLockContainer.visible = false
                        PinQueryAgent.simPinCompleted = true
                        lockScreen.unlock(lockScreen.pinQueryPannable && lockScreen.pinQueryPannable.deviceWasLocked)
                    }
                }
            }

            Connections {
                target: Desktop

                // This must be synchronized with tk_lock state. Hence, connect to
                // device lock state reported by Desktop.qml that is from system bus.
                onDeviceLockStateChanged: {
                    if (systemStarted.value && Desktop.deviceLockState === DeviceLock.Unlocked) {
                        if (!DeviceLock.enabled) {
                            if (deviceLockContainer.isCurrentItem) {
                                lockScreen.setCurrentItem(lockContainer, lockScreen.visible)
                            }
                        } else if (!lockScreen.nextPannableItem(true, false)) {
                            lockScreen.unlock(true)
                        } else if (lockScreen.pinQueryPannable) {
                            lockScreen.pinQueryPannable.deviceWasLocked = true
                        }
                    }
                }
            }

            Connections {
                target: DeviceLock

                onLocked: {
                    var lockedOut = DeviceLock.state > DeviceLock.Locked && DeviceLock.state < DeviceLock.Undefined

                    // On any lockout condition the active application should be hidden.
                    if (lockedOut) {
                        Lipstick.compositor.showApplicationOverLockscreen = false
                    }

                    if (!lockScreen.displayOn) {
                        // do nothing
                        return
                    } else if (lockedOut
                               || Lipstick.compositor.appLayer.window
                                || Lipstick.compositor.homeLayer.currentItem.maximized) {
                        lockScreen.nextPannableItem(false, false)
                        lockScreen.open(false)

                        if (lockedOut ) {
                            lipstickSettings.lockScreen(true)
                        }
                    } else {
                        lockScreen.activate(vignette.active)
                        lipstickSettings.lockScreen(true)
                    }

                }

                onNotice: {
                    switch (notice) {
                    case DeviceLock.SecurityCodeDueToExpire:
                        var expirationDate = new Date(data.expirationDate)

                        var oneday = 1000*60*60*24

                        var time = expirationDate.getTime() - new Date().getTime()
                        var days = Math.floor(time / oneday)

                        //% "Security code needs to be updated in %n day(s)"
                        expirationNotification.previewBody = qsTrId("lipstick-jolla-home-la-devicelock_expiring_in_days", days)

                        expirationNotification.timestamp = expirationDate
                        expirationNotification.expireTimeout = Math.min(time, oneday)

                        expirationNotification.publish()
                        Desktop.settings.security_code_notification_id = expirationNotification.replacesId
                        break
                    case DeviceLock.SecurityCodeChanged:
                        expirationNotification.close()
                        Desktop.settings.security_code_notification_id = 0
                        break
                    }
                }
            }

            Notification {
                id: expirationNotification
                category: "x-jolla.lipstick.devicelock.expiry"

                //% "Security"
                appName: qsTrId("lipstick-jolla-home-he-devicelock_security")
                //% "Device lock"
                previewSummary: qsTrId("lipstick-jolla-home-he-devicelock")
                summary: previewSummary
                body: previewBody
                replacesId: Desktop.settings.security_code_notification_id
                remoteActions: [ {
                    "name": "default",
                    "service": "com.jolla.settings",
                    "path": "/com/jolla/settings/ui",
                    "iface": "com.jolla.settings.ui",
                    "method": "showPage",
                    "arguments": [ "system_settings/security/device_lock" ]
                }]
            }


            NonGraphicalFeedback {
                id: unlockSuccessfulEvent
                event: "unlock_device"
            }

            Pannable {
                id: lockScreen

                property bool showPinQuery

                // For guarding lipstick startup. When device gets locked so that display is on
                // DeviceLock will trigger locking.
                property bool displayOn

                readonly property real peekOffset: peekFilter.progress * peekFilter.threshold
                readonly property bool lowPowerMode: lipstickSettings.lowPowerMode
                readonly property bool lockScreenAnimated: lipstickSettings.blankingPolicy == "default"
                            && !lockScreenPage.displayOnFromLowPowerMode

                readonly property bool pendingPannableItem: deviceLockItem.locked || needPinQuery

                // Suffix that should be added to all theme icons that are shown in low power mode
                property string iconSuffix: lipstickSettings.lowPowerMode ? ('?' + Theme.highlightColor) : ''

                property color textColor: Lipstick.compositor.lockScreenLayer.textColor
                readonly property bool locked: lipstickSettings.lockscreenVisible || Desktop.deviceLockState >= DeviceLock.Locked

                readonly property bool layerExposed: Lipstick.compositor.lockScreenLayer.exposed
                onLayerExposedChanged: {
                    if (!layerExposed) {
                        lockScreen.reset()

                        if (pinQueryPannable) {
                            pinQueryPannable.destroy()
                            pinQueryPannable = null
                        }
                    }

                    if (!deviceLockContainer.isCurrentItem) {
                        deviceLockContainer.visible = false
                    }
                }

                readonly property real progress: Math.min(Math.abs(absoluteProgress / peekFilter.threshold), 1.0)

                // If startup wizard is running it will show the pin query. Show only when device started and sim pin is required.
                readonly property bool needPinQuery: !Desktop.startupWizardRunning && PinQueryAgent.simPinRequired && (!PinQueryAgent.simPinCompleted || showPinQuery)
                onNeedPinQueryChanged: {
                    // In case device is not locked. Create pin query conditionally for the pannable.
                    if (needPinQuery) {
                        createPinQueryIfNeeded()
                    }
                }

                property PannableItem pinQueryPannable

                signal gestureTriggered

                function open(showPin) {
                    // When proximity was covered right after dimming goes away and display goes off
                    // we will return to low power mode
                    showPinQuery = showPin
                    createPinQueryIfNeeded()
                    vignette.active = !lockScreen.lowPowerMode
                }

                function activate(vignetteActive) {
                    // Handles also immediate locking via power key
                    lockScreen.reset()
                    deviceLockContainer.opacity = 1.0
                    deviceLockContainer.visible = false
                    if (pinQueryPannable) {
                        pinQueryPannable.visible = false
                        if (!vignetteActive || PinQueryAgent.simPinCompleted || deviceLockItem.locked) {
                            pinQueryPannable.destroy()
                            pinQueryPannable = null
                        }

                    }
                    vignette.active = vignetteActive
                }

                function unlock(playTone) {
                    if (!lockScreenPage.displayIsOn)
                        return false

                    if (playTone) {
                        unlockSuccessfulEvent.play()
                    }

                    // Lipstick.compositor.unlocked signal is emitted when we can unlock and showPinQuery cannot block unlocking
                    // from this point onwards.
                    lockScreen.showPinQuery = false
                    if (lockScreen.pinQueryPannable) {
                        lockScreen.pinQueryPannable.deviceWasLocked = false
                    }

                    if ((lockContainer.x > 0 || overshoot > 0)
                            && (Lipstick.compositor.notificationOverviewLayer.hasNotifications || Desktop.settings.left_peek_to_events)
                            && Lipstick.compositor.systemInitComplete) {
                        lockItem.reset()
                        deviceLockContainer.opacity = 0.0
                        if (Lipstick.compositor.notificationOverviewLayer.hasNotifications && overshoot > 0) {
                            Lipstick.compositor.lockScreenLayer.notificationAnimation = "animated"
                        } else {
                            Lipstick.compositor.lockScreenLayer.notificationAnimation = "immediate"
                            Lipstick.compositor.goToEvents()
                        }
                    } else {
                        lockItem.reset()
                        Lipstick.compositor.goToSwitcher(false)
                    }

                    return true
                }

                function createPinQueryIfNeeded() {
                    if (lockScreen.needPinQuery && !lockScreen.pinQueryPannable && !deviceLockItem.locked) {
                        // Sibling of the device lock.
                        lockScreen.pinQueryPannable = pinQueryComponent.createObject(deviceLockContainer.parent)
                    }
                }

                function nextPannableItem(animate, interactive, direction) {
                    lockContainer.interactive = interactive
                    var pannable = null
                    if (deviceLockItem.locked) {
                        pannable = deviceLockContainer
                    } else if (lockScreen.needPinQuery) {
                        lockScreen.createPinQueryIfNeeded()
                        pannable = lockScreen.pinQueryPannable
                    }

                    if (pannable) {
                        lockScreen.setCurrentItem(pannable, animate, direction)
                    }
                    return !!pannable
                }

                function reset() {
                    lockContainer.interactive = true
                    setCurrentItem(lockContainer, false)
                }

                width: parent.width
                height: parent.height
                currentItem: lockContainer
                focus: true

                onLowPowerModeChanged: {
                    if (lowPowerMode) {
                        vignette.active = false
                    }
                }

                onGestureTriggered: {
                    // Doesn't handle pin query.
                    if (!deviceLockItem.locked && !lockScreen.needPinQuery) {
                        lockScreen.unlock(false)
                    }
                }

                onPanningChanged: {
                    if (!panning && progress == 1.0) {
                        lockScreen.gestureTriggered()
                    }
                }

                peekFilter {
                    enabled: !lockScreen.lowPowerMode && !Lipstick.compositor.notificationOverviewLayer.revealingEventsView && lockScreen.locked && !Desktop.startupWizardRunning
                    // Tune this to allow the best possible experience regarding opening the lock
                    // Currently Clock and EdgeIndicators are animated separately.
                    threshold: Theme.itemSizeLarge + lockItem.indicatorSize

                    bottomEnabled: lockContainer.isCurrentItem && (deviceLockItem.locked || lockScreen.needPinQuery)
                    onBottomActiveChanged: {
                        if (peekFilter.bottomActive) {
                            lockItem.hintEdges()
                        }
                    }
                }

                dragArea.enabled: peekFilter.enabled

                pannableItems: [
                    PannableItem {
                        id: lockContainer

                        property bool interactive: true

                        readonly property bool resetDefaults: !lockScreen.moving && isCurrentItem
                        readonly property Item nextItem: deviceLockItem.locked ? deviceLockContainer : lockScreen.pinQueryPannable

                        readonly property bool atLeft: interactive && x <= 0
                        readonly property bool atRight: interactive && x >= 0

                        objectName: "lockContainer"

                        width: lockScreen.width
                        height: lockScreen.height
                        leftItem: nextItem
                        rightItem: nextItem

                        onVisibleChanged: {
                            if (visible) {
                                lockScreen.createPinQueryIfNeeded()
                            }
                        }

                        onResetDefaultsChanged: {
                            if (resetDefaults) {
                                deviceLockItem.reset()
                                if (lockScreen.pinQueryPannable) {
                                    lockScreen.pinQueryPannable.reset()
                                }
                            }
                        }

                        LockItem {
                            id: lockItem
                            anchors.fill: parent
                            contentTopMargin: Math.round(parent.height / 8)
                            statusBarHeight: statusBar.height

                            visible: systemStarted.value
                            allowAnimations: vignette.opened
                            iconSuffix: lockScreen.iconSuffix
                            clock.followPeekPosition: !parent.rightItem

                            Binding { target: lockItem.mpris.item; property: "enabled"; value: !lockScreen.lowPowerMode }
                        }
                    },

                    PannableItem {
                        id: deviceLockContainer

                        function pinOrLock() {
                            return lockScreen.needPinQuery ? lockScreen.pinQueryPannable : lockContainer
                        }

                        width: lockScreen.width
                        height: lockScreen.height

                        leftItem: lockContainer.atLeft ? lockContainer : pinOrLock()
                        rightItem: lockContainer.atRight ? lockContainer : pinOrLock()

                        objectName: "deviceLock"
                        visible: false

                        onIsCurrentItemChanged: {
                            Lipstick.compositor.lockScreenLayer.showingLockCodeEntry = isCurrentItem
                        }

                        // Fadeout device lock faster when unlocking to events view so that device lock is not visible
                        // when NotificationLayer animates visible.
                        Behavior on opacity {
                            enabled: lockContainer.atRight && !lockScreen.pinQueryPannable
                            FadeAnimation {}
                        }

                        DeviceLockPrompt {
                            id: deviceLockItem

                            width: parent.width
                            height: parent.height
                            opacity: vignette.opened && item
                                        && item.authenticationInput.status !== AuthenticationInput.Idle
                                    ? 1
                                    : 0
                            headingVerticalOffset: statusBar.y + statusBar.height + Theme.paddingLarge

                            enabled: locked && !lockScreen.moving && deviceLockContainer.isCurrentItem
                            focus: !Desktop.startupWizardRunning

                            Behavior on opacity {
                                enabled: deviceLockContainer.visible
                                FadeAnimation {}
                            }
                        }
                    }
                ]
            }

            Component {
                id: pinQueryComponent

                PannableItem {
                    id: pinQueryContainer

                    property Item previousPannableItem: deviceLockItem.locked ? deviceLockContainer : lockContainer
                    property bool deviceWasLocked

                    function reset() {
                        pinQuery.reset()
                    }

                    width: lockScreen.width
                    height: lockScreen.height

                    leftItem: lockContainer.atLeft ? previousPannableItem : null
                    rightItem: lockContainer.atRight ? previousPannableItem : null
                    objectName: "pinQueryContainer"

                    visible: false

                    // Would be better if this would be out-process window. Then we'd free resources.
                    PinQueryWindow {
                        id: pinQuery

                        function hide() {
                            // Hide device lock so that it doesn't flicker when pin query is fading away.
                            deviceLockContainer.visible = false
                            PinQueryAgent.simPinCompleted = true
                            lockScreen.unlock(deviceWasLocked)
                        }

                        anchors.fill: parent
                        modemPath: PinQueryAgent.modemPath

                        onSkipped: {
                            if (PinQueryAgent.skipSimPin()) {
                                hide()
                            }
                        }

                        onPinConfirmed: {
                            if (!PinQueryAgent.simPinRequired) {
                                hide()
                            }
                        }
                    }
                }
            }

            Component.onCompleted: PinQueryAgent.enabled = true
        }
    }
}
