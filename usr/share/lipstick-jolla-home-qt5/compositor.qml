/****************************************************************************
**
** Copyright (c) 2013 - 2020 Jolla Ltd.
** Copyright (c) 2020 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************/

import QtQuick 2.2
import QtQuick.Window 2.2 as QtQuick
import org.nemomobile.lipstick 0.1
import org.nemomobile.configuration 1.0
import org.nemomobile.systemsettings 1.0
import org.nemomobile.devicelock 1.0
import Nemo.DBus 2.0 as NemoDBus
import Nemo.FileManager 1.0
import Sailfish.Silica 1.0
import Sailfish.Silica 1.0 as SS
import Sailfish.Ambience 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Lipstick 1.0
import com.jolla.lipstick 0.1

import "layers"
import "launcher"
import "compositor"
import "main"
import "windowwrappers"

Compositor {
    id: root

    // The window ID of the topmost window
    topmostWindowId: topmostWindow && topmostWindow.window ? topmostWindow.window.windowId : 0
    property Item topmostWindow
    property Item exposedWindow
    property Item previousWindow

    color: wallpaper.exposed && !incomingAlarm ? "transparent" : "black"

    readonly property Item obscuredWindow: {
        if (alarmLayerItem.window && alarmLayerItem.window != topmostWindow) {
            return alarmLayerItem.window
        } else if (!dialogLayerItem.locked
                    && dialogLayerItem.window
                    && dialogLayerItem.window != topmostWindow) {
            return dialogLayerItem.window
        } else if (showApplicationOverLockscreen
                   && appLayerItem.window
                   && appLayerItem.window != topmostWindow) {
            return appLayerItem.window
        } else if (showApplicationOverLockscreen
                   && homeLayerItem.currentItem.maximized
                   && homeLayerItem.window != topmostWindow) {
            return homeLayerItem.window
        } else if (lockScreenLayer.locked && lockScreenLayerItem.window != topmostWindow) {
            return lockScreenLayerItem.window
        } else if (appLayerItem.window && appLayerItem.window != topmostWindow) {
            return appLayerItem.window
        } else {
            return homeLayerItem.window
        }
    }

    // Home will be obscured if any of the layers stacking on top of it is opaque.
    readonly property bool homeVisible: !(peekLayer.opaque || (root.deviceIsLocked && lockScreenLayer.opaque))
                || (homeLayerItem.currentItem.maximized && !(launcherLayerItem.opaque
                || topMenuLayerItem.opaque
                || alarmLayerItem.opaque
                || dialogLayerItem.opaque))

    homeActive: homeLayerItem.active

    // Set to the window id of the window the user is using the closing gesture on, or 0 if no such window
    // Emitted when the closing gesture is triggered
    // Windows that have been requested to be closed
    property var windowsBeingClosed: []

    property alias wallpaper: wallpaperItem
    property alias launcherLayer: launcherLayerItem
    property alias homeLayer: homeLayerItem
    property alias appLayer: appLayerItem
    property alias lockScreenLayer: lockScreenLayerItem
    property alias dialogLayer: dialogLayerItem
    property alias alarmLayer: alarmLayerItem
    property alias topMenuLayer: topMenuLayerItem
    property alias cameraLayer: cameraLayerItem
    property alias switcherLayer: homeLayerItem.switcher
    property alias eventsLayer: homeLayerItem.events
    property alias peekingLayer: peekLayer
    property alias notificationOverviewLayer: notificationOverviewLayerItem
    property alias shutdownLayer: shutdownLayerItem

    property alias volumeGestureFilterItem: globalVolumeGestureItem
    // Needs more prototyping, disable by default. See JB#40618
    readonly property bool quickAppToggleGestureExceeded: experimentalFeatures.quickAppToggleGesture && peekLayer.quickAppToggleGestureExceeded

    property alias launcherHinting: launcherLayerItem.hinting
    property alias topMenuHinting: topMenuLayerItem.hinting
    readonly property bool launcherPeeking: launcherLayerItem.exposed && !launcherLayerItem.opaque
    onLauncherPeekingChanged: {
        if (launcherPeeking) {
            switcherLayer.setHousekeeping(false)
            eventsLayer.setHousekeeping(false)
        }
    }

    readonly property bool peekingAtHome: peekLayer.peeking
    readonly property bool topMenuPeeking: topMenuLayerItem.exposed && !topMenuLayerItem.opaque
    onTopMenuPeekingChanged: {
        if (topMenuPeeking) {
            switcherLayer.setHousekeeping(false)
            eventsLayer.setHousekeeping(false)
        }
    }

    property bool showApplicationOverLockscreen
    property bool incomingAlarm
    property bool currentAlarm

    property bool volumeWarningVisible

    property bool powerKeyPressed

    // When true the device unlock screen will be shown immediately during displayAboutToBeOn.
    // Set when display is turned on with double power key press or when plugging in USB cable
    property bool showDeviceLock

    // True if only the current notification window is allowed to be visible
    property bool onlyCurrentNotificationAllowed

    property bool isLegacyWallpaper: wallpaperItem.isLegacyWallpaper

    topmostWindowOrientation: {
        if (alarmLayerItem.window && !alarmLayerItem.renderDialogBackground) {  // test for full-screen alarm/call window
            return alarmLayerItem.window.orientation
        } else if (showApplicationOverLockscreen && appLayerItem.window) {
            return appLayerItem.window.orientation
        } else if (showApplicationOverLockscreen && homeLayerItem.currentItem.maximized) {
            return homeLayerItem.window.orientation
        } else if (screenIsLocked && lockScreenLayerItem.window) {
            return lockScreenLayerItem.window.orientation
        } else if (appLayerItem.window) {
            return appLayerItem.window.orientation
        } else if (homeLayerItem.window) {
            return homeLayerItem.window.orientation
        } else {
            return QtQuick.Screen.primaryOrientation
        }
    }
    property int topmostWindowAngle: QtQuick.Screen.angleBetween(topmostWindowOrientation, QtQuick.Screen.primaryOrientation)
    onSensorOrientationChanged: updateScreenOrientation()
    onOrientationLockChanged: updateScreenOrientation()
    onTopmostWindowChanged: updateWindows()
    onTopmostWindowOrientationChanged: Desktop.settings.dialog_orientation = topmostWindowOrientation

    readonly property real topmostWindowHeight: topmostWindowAngle % 180 == 0 ? height : width

    property int homeOrientation: Qt.PortraitOrientation

    property bool directRendering: appLayer.active && !homeLayer.visible && topmostWindow && topmostWindow.window
                                   && !topmostWindow.window.isInProcess
                                   && !(dialogLayer.contentItem.children.length > 1
                                        || alarmLayer.contentItem.children.length > 1
                                        || notificationLayer.contentItem.children.length
                                        || launcherLayer.visible
                                        || overlayLayer.contentItem.childrenRect.width
                                        || overlayLayer.contentItem.childrenRect.height)
    fullscreenSurface: directRendering ? topmostWindow.window.surface : null
    screenOrientation: {
        if (orientationLock == "portrait") return Qt.PortraitOrientation
        else if (orientationLock == "portrait-inverted") return Qt.InvertedPortraitOrientation
        else if (orientationLock == "landscape") return Qt.LandscapeOrientation
        else if (orientationLock == "landscape-inverted") return Qt.InvertedLandscapeOrientation

        return QtQuick.Screen.primaryOrientation
    }
    keymap: Keymap {
        rules: keymapConfig.rules
        model: keymapConfig.model
        layout: keymapConfig.layout
        variant: keymapConfig.variant
        options: keymapConfig.options
    }

    readonly property alias blurPeek: peekBlurSource.blur
    readonly property alias blurHome: homeBlurSource.blur
    readonly property alias blurApplication: applicationBlurSource.blur
    readonly property alias blurLockscreen: lockscreenBlurSource.blur
    readonly property Item blurSource: {
        if (blurPeek) {
            return peekBlurSource.provider
        } else if (blurHome) {
            return homeBlurSource.provider
        } else {
            return null
        }
    }
    readonly property Item dialogBlurSource: {
        if (blurApplication) {
            return applicationBlurSource.provider
        } else if (blurLockscreen) {
            return lockscreenBlurSource.provider
        } else if (blurHome) {
            return homeBlurSource.provider
        } else {
            return null
        }
    }

    property var desktop

    PeekFilter.pressDelay: peekFilterConfigs.pressDelay
    PeekFilter.threshold: QtQuick.Screen.pixelDensity * 10 // 10mm
    PeekFilter.enabled: !systemGesturesDisabled
    PeekFilter.boundaryWidth: peekFilterConfigs.boundaryWidth
    PeekFilter.boundaryHeight: peekFilterConfigs.boundaryHeight
    PeekFilter.orientation: topmostWindowOrientation
    PeekFilter.keyboardBoundaryWidth: peekFilterConfigs.keyboardBoundaryWidth
    PeekFilter.keyboardBoundaryHeight: peekFilterConfigs.keyboardBoundaryHeight

    ConfigurationGroup {
        id: peekFilterConfigs
        path: "/desktop/lipstick-jolla-home/peekfilter"
        property int boundaryWidth: Theme.paddingLarge
        property int boundaryHeight: Theme.paddingLarge
        property int keyboardBoundaryWidth: boundaryWidth / 2
        property int keyboardBoundaryHeight: boundaryHeight / 2
        property int pressDelay: 400
    }

    readonly property bool sidePeek: peekLayer.peekFilter.leftActive || peekLayer.peekFilter.rightActive
    readonly property bool homePeek: !homeActive && sidePeek
    // True when the user is peeking through to the home window
    property bool homePeeking: !homeActive && homePeek

    readonly property bool topmostWindowRequestsGesturesDisabled: topmostWindow && topmostWindow.window
                                                                  && topmostWindow.window.surface
                                                                  && (topmostWindow.window.surface.windowFlags & 1)

    readonly property bool topmostIsDialog: dialogLayerItem.active
    readonly property bool systemGesturesDisabled: !lockScreenLayer.active && (topmostIsDialog || topmostWindowRequestsGesturesDisabled)

    // Locked or Undefined == Locked
    readonly property bool deviceIsLocked: Desktop.deviceLockState >= DeviceLock.Locked
                || lockScreenLayer.pendingPinQuery
                || Desktop.startupWizardRunning
    readonly property bool screenIsLocked: lipstickSettings.lockscreenVisible

    property alias systemInitComplete: initDoneFile.exists

    property real statusBarPushDownY: { return 0 }
    readonly property bool largeScreen: SS.Screen.sizeCategory >= SS.Screen.Large

    property string _peekDirection
    property bool _displayOn

    // Emitted before transitioning to a home layer.  The lockscreen connects to this and either
    // clears its locked status allowing home to gain focus, or shows the pin query if the device
    // is locked.
    signal unlock()
    signal peekGestureStarted(string direction)
    signal peekGestureReset()
    signal minimizeLaunchingWindows

    onVisibleChanged: {
        if (visible && !incomingAlarmTimer.running) {
            _resetIncomingAlarm()
        } else if (!visible) {
            layersParent.visible = false
        }
    }

    function goToHome(layer, minimize) {
        homeLayerItem.lastActiveLayer = layer
        homeLayerItem.setCurrentItem(layer, homeVisible)
        if (minimize) {
            appLayerItem.hide()
            alarmLayerItem.hide()
            topMenuLayer.hide()
        }
        if (lipstickSettings.lockscreenVisible) {
            unlock()
        } else {
            setCurrentWindow(!minimize && appLayerItem.window
                    ? appLayerItem.window
                    : homeLayerItem.window)
        }
    }

    function goToSwitcher(minimize) { goToHome(homeLayerItem.switcher, minimize) }
    function goToEvents() { goToHome(homeLayerItem.events, true) }

    function goToApplication(winId) {
        var window = windowForId(winId)

        if (window && window.userData) {
            if (appLayerItem.window == window.userData) {
                homeLayerItem.lastActiveLayer = homeLayerItem.switcher
                homeLayerItem.setCurrentItem(homeLayerItem.switcher, homeVisible)
                alarmLayerItem.hide()
                if (lipstickSettings.lockscreenVisible) {
                    unlock()
                } else {
                    setCurrentWindow(window.userData)
                }
            } else {
                goToSwitcher(true)
                raiseWindow(window)
            }
        }
    }

    function _resetIncomingAlarm() {
        if (!alarmLayerItem.transitioning && root.visible) {
            layersParent.visible = true
            incomingAlarm = false
            alarmLayerItem.parent = alarmApplicationForeground
        }
    }

    FileWatcher {
        id: initDoneFile
        // init-done file appears when the boot finishes
        fileName: "/run/systemd/boot-status/init-done"
    }

    ConfigurationGroup {
        id: experimentalFeatures

        path: "/desktop/sailfish/experimental"
        property bool quickAppToggleGesture
    }

    MultiPointTouchDrag {
        id: globalVolumeGestureItem

        enabled: !systemGesturesDisabled && largeScreen
        orientation: Lipstick.compositor.topmostWindowOrientation
        fingers: 3
        direction: MultiPointTouchDrag.Vertical
    }

    function updateScreenOrientation() {
        if (orientationLock == "portrait") {
            screenOrientation = (sensorOrientation & Qt.PortraitOrientation)
                        || Qt.PortraitOrientation
        } else if (orientationLock == "portrait-inverted") {
            screenOrientation = (sensorOrientation & Qt.InvertedPortraitOrientation)
                        || Qt.InvertedPortraitOrientation
        } else if (orientationLock == "landscape-inverted") {
            screenOrientation = (sensorOrientation & Qt.InvertedLandscapeOrientation)
                        || Qt.InvertedLandscapeOrientation
        } else if (orientationLock == "landscape") {
            screenOrientation = (sensorOrientation & Qt.LandscapeOrientation)
                        || Qt.LandscapeOrientation
        } else if (QtQuick.Screen.angleBetween(screenOrientation, sensorOrientation) != 0) {
            if (root.PeekFilter.activeTouches <= 0) {
                screenOrientation = sensorOrientation
            }
        }
    }

    function windowToFront(winId) {
        var window = windowForId(winId)

        if (window && window.userData) {
            raiseWindow(window)
        }
    }

    function toplevelForWindow(window) {
        var transientWindow = window
        while (window.surface && window.surface.transientParent) {
            if (window.surface.transientParent !== window.parent.surface) {
                console.log("transient/item ancestry mismatch for window [title=", transientWindow.title, ", category=", transientWindow.category, "]")
                return transientWindow
            }

            // look for closest toplevel in parent chain
            window = window.parent
        }
        return window
    }


    // Focuses a window within application context, but
    // does not focus the application itself -- kind of
    // local forceActiveFocus
    function focusTransientInLocalScope(toplevel, transientWindow) {

        // First, clear previous focus (only in case application is already focused)
        //  - unfocus is needed to transfer the focus from child window
        //    to parent window

        // is active focus item descendant of "toplevel" ?
        var oldFocusItem = root.activeFocusItem
        while (oldFocusItem && oldFocusItem !== toplevel) {
            oldFocusItem = oldFocusItem.parent
        }

        // yes it was. clear previous focus chain up until
        // "toplevel"
        if (oldFocusItem === toplevel) {
            oldFocusItem = root.activeFocusItem
            while (oldFocusItem !== toplevel) {
                oldFocusItem.focus = false
                oldFocusItem = oldFocusItem.parent
            }
        }

        while (transientWindow !== toplevel) {
            transientWindow.focus = true
            transientWindow = transientWindow.parent
        }
    }

    function raiseWindow(window) {
        var transientWindow = window
        window = toplevelForWindow(window)

        switch (window ? window.userData.windowType : WindowType.Internal) {
        case WindowType.Alarm:
            if (!root.visible) {
                prepareToShowAlarm()
            }
            alarmLayerItem.show(window.userData)
            break
        case WindowType.Dialog:
            dialogLayerItem.show(window.userData)
            break
        case WindowType.Application:
            appLayerItem.show(window.userData)
            break
        case WindowType.PartnerSpace:
            appLayerItem.hide()
            homeLayerItem.partnerWindowRaised(window.userData)
            break
        }

        Lipstick.compositor.topMenuLayer.hide()
        focusTransientInLocalScope(window, transientWindow)
    }

    function setCurrentWindow(w, force) {
        if (debug) {
            console.log("Compositor: Set current window: \"", w, "\"")
            console.log("Compositor: Current top most window: \"", topmostWindow ,"\" forced: ", force)
        }

        if (w == topmostWindow || w == topMenuLayerItem.window)
            return

        // We're changing the current window, hide top menu.
        topMenuLayerItem.hide()

        if (w == alarmLayerItem.window) {
            // Nothing to do, allow this window to become current window.
        } else if (alarmLayerItem.window && !force) {
            if (w != launcherLayerItem.window) {
                return
            }
        } else if (!dialogLayerItem.locked && w == dialogLayerItem.window) {
            // Nothing to do, allow this window to become current window.
        } else if (!root.deviceIsLocked && dialogLayerItem.window && !force) {
            return
        } else if (w == cameraLayerItem.window
                   || (showApplicationOverLockscreen && w == appLayerItem.window)) {
            // Nothing to do, allow this window to become current window.
        } else if (w == lockScreenLayerItem.window) {
            homeLayerItem.lastActiveLayer = homeLayerItem.switcher
            showApplicationOverLockscreen = Desktop.startupWizardRunning
            if (!lipstickSettings.lockscreenVisible) {
                minimizeLaunchingWindows()
                lipstickSettings.lockScreen(true)
            }
        } else if (w == launcherLayer.window) {
            minimizeLaunchingWindows()
        } else if (lipstickSettings.lockscreenVisible || root.deviceIsLocked) {
            // Home and applications windows can't be given focus if the lockscreen is locked.
            return
        } else if (w.windowType == WindowType.PartnerSpace) {
            showApplicationOverLockscreen = true
            homeLayerItem.lastActiveLayer = w.layerItem
            minimizeLaunchingWindows()
        } else if (w == homeLayerItem.events.window) {
            homeLayerItem.lastActiveLayer = homeLayerItem.events
            minimizeLaunchingWindows()
        } else if (w == homeLayerItem.switcher.window) {
            homeLayerItem.lastActiveLayer = homeLayerItem.switcher
        } else if (w == appLayerItem.window) {
            homeLayerItem.lastActiveLayer = homeLayerItem.switcher
            showApplicationOverLockscreen = true
        }

        if (w.window) {
            w.window.forceActiveFocus()
        } else {
            // The lock screen camera ia a special case layer where the window can be created after
            // the fact.
            w.forceActiveFocus()
        }

        previousWindow = exposedWindow = topmostWindow
        topmostWindow = w
        exposedWindow = null
    }

    function updateWindows(keepOrientation)
    {
        var windows = new Array
        if (alarmLayer.window) windows.push(alarmLayer.window.window)
        else if (dialogLayer.window) windows.push(dialogLayer.window.window)
        else if (topmostWindow) windows.push(topmostWindow.window)

        var overlays = overlayLayer.contentItem.children
        for (var ii = 0; ii < overlays.length; ++ii)
            windows.push(overlays[ii].window)
        // Lipstick does not use real Qt windows.  Instead, all "windows"
        // within the lipstick home application are just special QtQuick
        // items added to a single global scene.
        // In order for Silica components to behave the same within lipstick
        // as they do in regular windowed applications, Silica must be informed
        // of these pretend windows and their stacking order when running
        // inside lipstick.  At the moment the only Silica component that uses
        // this information is InverseMouseArea.
        // The compositor window list should contain all the visible "windows"
        // in their stacking order, from bottom to top.  Fully obscured
        // windows can be omitted - which is why we just include the topmost
        // window above - and invisible windows may NOT be included.
        Config.setCompositorWindows(windows)

        if (!keepOrientation) {
            updateScreenOrientation()
        }
    }

    function isLipstickCompositorWindow(item) {
        // XXX what's the proper way?
        return item && item.hasOwnProperty("focusOnTouch") && item.surface
    }

    function prepareToShowAlarm() {
        if (!currentAlarm) {
            alarmLayerItem.parent = alarmLayersForeground
            incomingAlarmTimer.restart()
            currentAlarm = true
            incomingAlarm = true
        }
    }

    LayersParent {
        id: layersParent

        // Disable opening of top menu by dragging when home is in housekeeping mode
        property bool homeHouseKeeping: switcherLayer.housekeeping || eventsLayer.housekeeping

        orientationAngle: topmostWindowAngle
        anchors.fill: parent
        launcherInteractiveArea {
            enabled: launcherLayerItem.edgeFilter.enabled && (homeLayerItem.active || launcherLayerItem.active)
            drag.target: launcherLayerItem

        }

        topMenuInteractiveArea {
            enabled: !homeHouseKeeping && topMenuLayerItem.edgeFilter.enabled && (homeLayerItem.active || topMenuLayerItem.exposed)
            drag.target: topMenuLayerItem
        }

        BlurSource {
            id: homeBlurSource

            blur: (homeVisible || (deviceIsLocked && lockScreenLayerItem.opaqueAndMapped))
                  && ((!peekBlurSource.blur
                        && (topMenuLayer.exposed
                            || launcherLayerItem.exposed
                            || unresponsiveApplicationDialog.windowVisible
                            || root.volumeWarningVisible))
                    || (!applicationBlurSource.blur
                        && !lockscreenBlurSource.blur
                        && ((dialogLayerItem.exposed && dialogLayerItem.renderDialogBackground)
                            || (alarmLayerItem.exposed && alarmLayerItem.renderDialogBackground)))
                      )

            anchors.fill: parent

            Item {
                id: wallpaperBelowHome

                anchors.fill: parent

                HomeWallpaper {
                    id: wallpaperItem

                    parent: {
                        if (!peekLayer.exposed || !peekLayer.opaque) {
                            return wallpaperBelowHome
                        } else if (lockscreenBlurSource.blur) {
                            return wallpaperBelowLockscreen
                        } else {
                            return wallpaperWithinPeek
                        }
                    }

                    anchors.fill: parent

                    onTransitionComplete: ambienceChangeTimeout.running = false
                    onRotationComplete: {
                        if (root.homeVisible) {
                            homeBlurSource.update()
                            peekBlurSource.update()
                            lockscreenBlurSource.update()
                        }
                    }
                }
            }

            Item {
                id: homeBelowPeek

                anchors.fill: parent
                visible: root.homeVisible
            }

            HomeLayer {
                id: homeLayerItem

                parent: root.deviceIsLocked
                        ? homeWithinPeek
                        : homeBelowPeek

                enabled: root.homeActive && !wallpaperItem.transitioning && !ambienceChangeTimeout.running
                opacity: wallpaperItem.transitioning || ambienceChangeTimeout.running ? 0.0 : 1.0
                Behavior on opacity { FadeAnimator { duration: 300; alwaysRunToEnd: true } }

                peekFilter.enabled: !root.deviceIsLocked

                ThemeTransaction {
                    deferAmbience: wallpaperItem.transitioning || ambienceChangeTimeout.running || topMenuLayerItem.transitioning
                    onAmbienceAboutToChange: {
                        if (homeLayerItem.visible || lockScreenLayerItem.exposed) {
                            ambienceChangeTimeout.running = true
                        }
                    }
                }

                Timer {
                    id: ambienceChangeTimeout
                    interval: 500
                }
            }

            Item {
                id: lockscreenHomeForeground
                anchors.fill: parent
            }

            Item {
                id: notificationHomeForeground

                anchors.fill: parent

                NotificationOverviewLayer {
                    id: notificationOverviewLayerItem

                    lockScreenLocked: (root.screenIsLocked && !peekLayer.peeking) || root.deviceIsLocked
                    parent: lockScreenLayerItem.exposed
                            ? notificationLockscreenForeground
                            : notificationHomeForeground
                }
            }

            Item {
                id: dialogHomeForeground

                anchors.fill: parent
            }
        }

        RotatingItem {
            id: indicatorHomeForeground

            LayerEdgeIndicator {
                id: topmenuEdgeHandle

                property bool earlyFadeout

                rotation: 180
                exposed: systemInitComplete && topMenuLayer.exposed && !earlyFadeout
                opacity: topMenuLayerItem.closeFromEdge ? topMenuLayerItem.contentOpacity : (exposed ? 1.0 : 0.0)
                opacityBehavior.enabled: !topMenuLayerItem.closeFromEdge

                parent: peekLayer.exposed && !peekLayer.peeking
                        ? indicatorApplicationForeground
                        : indicatorHomeForeground
                y: (indicatorHomeForeground.inverted ? -1 : 1) * (indicatorHomeForeground.transposed
                                                                  ? -topMenuLayer.x : topMenuLayer.y)
                   + (topMenuLayer.topMenu ? topMenuLayer.topMenu.height : 0)
            }

            LayerEdgeIndicator {
                id: launcherEdgeHandle
                parent: peekLayer.exposed && !peekLayer.peeking
                        ? indicatorApplicationForeground
                        : indicatorHomeForeground
                exposed: systemInitComplete && !topMenuLayer.exposed
                         && (launcherLayer.exposed || (homeLayer.active && homeLayer.wallpaperVisible))
                offset: (indicatorHomeForeground.inverted ? -1 : 1)
                        * (indicatorHomeForeground.transposed ? -launcherLayer.x : launcherLayer.y)
            }
        }

        Layer {
            id: peekLayer

            property bool hasChildWindows: true
            readonly property bool isFullScreen: !topMenuLayerItem.exposed

            background: {
                if ((alarmLayerItem.opaque && alarmLayerItem.renderBackground)
                            || (appLayerItem.opaque && appLayerItem.renderBackground)) {
                    return appBgContainer
                } else if (!root.deviceIsLocked
                            && lockScreenLayerItem.opaque
                            && lockScreenLayerItem.renderBackground) {
                    return wallpaperItem
                } else {
                    return null
                }
            }

            window: contentItem
            exposed: appLayerItem.exposed
                        || cameraLayerItem.exposed
                        || alarmLayerItem.exposed
                        || launcherLayerItem.exposed
                        || topMenuLayerItem.exposed
                        || dialogLayerItem.exposed
                        || (!root.deviceIsLocked && lockScreenLayer.exposed)
                        || (root.deviceIsLocked && homeLayerItem.currentItem.maximized)
            childrenOpaque: appLayerItem.opaque
                        || cameraLayerItem.opaque
                        || launcherLayerItem.opaque
                        || topMenuLayerItem.opaque
                        || alarmLayerItem.opaque
                        || dialogLayerItem.opaque
                        || (!root.deviceIsLocked && lockScreenLayer.opaque)
                        || (root.deviceIsLocked && homeLayerItem.currentItem.maximized)

            renderBackground: (appLayerItem.exposed && appLayerItem.renderBackground)
                        || (alarmLayerItem.exposed && alarmLayerItem.renderBackground)
                        || (alarmLayerItem.exposed && alarmLayerItem.renderDialogBackground)
                        || (dialogLayerItem.exposed && dialogLayerItem.renderDialogBackground)
                        || (!root.deviceIsLocked && lockScreenLayerItem.exposed)

            mergeWindows: (appLayerItem.exposed && appLayerItem.mergeWindows)
                        || (alarmLayerItem.exposed && alarmLayerItem.mergeWindows)
                        || (dialogLayerItem.exposed && dialogLayerItem.mergeWindows)
                        || (launcherLayerItem.exposed && launcherLayerItem.mergeWindows)
                        || (topMenuLayerItem.exposed && topMenuLayerItem.mergeWindows)
                        || (!root.deviceIsLocked && lockScreenLayerItem.exposed && lockScreenLayerItem.mergeWindows)

            peekFilter {
                enabled: appLayerItem.active
                            || cameraLayerItem.active
                            || launcherLayerItem.active
                            || alarmLayerItem.active
                            || topMenuLayerItem.active
                            || (homeLayerItem.active && root.deviceIsLocked)
                leftEnabled: !Desktop.startupWizardRunning
                rightEnabled: !Desktop.startupWizardRunning
                extraGestureThreshold: QtQuick.Screen.pixelDensity * 30 // 30mm
                extraGestureDuration: 500

                onGestureStarted: {
                    if (isFullScreen) {
                        root._peekDirection = peekFilter.leftActive ? "right" : "left"
                        homeLayerItem.lastActiveLayer = homeLayerItem.currentItem
                        root.peekGestureStarted(root._peekDirection)
                        if (root.deviceIsLocked && homeLayerItem.currentItem.maximized) {
                            // Retain the partner space as the current home item if the device is locked.
                        } else if (peekFilter.leftActive && Desktop.settings.left_peek_to_events) {
                            homeLayerItem.setCurrentItem(homeLayerItem.events, !childrenOpaque, root._peekDirection)
                        } else {
                            homeLayerItem.setCurrentItem(homeLayerItem.switcher, !childrenOpaque, root._peekDirection)
                        }
                    }
                    if (peekLayer.mergeWindows) {
                        transitionOptimizer.cacheWindow(peekLayer)
                    }
                }

                onGestureTriggered: {
                    if (!Desktop.startupWizardRunning
                            && !(topMenuLayerItem.active && root.deviceIsLocked)) {
                        root.unlock()
                    }
                }
                onGestureReset: {
                    if (isFullScreen) {
                        homeLayerItem.setCurrentItem(
                                    homeLayerItem.lastActiveLayer || homeLayerItem.switcher,
                                    !childrenOpaque,
                                    root._peekDirection == "left" ? "right" : "left")
                        root.peekGestureReset()
                    }
                }

                onExtraGestureTriggered: {
                    if (experimentalFeatures.quickAppToggleGesture) {
                        var switcher = Desktop.instance && Desktop.instance.switcher
                        switcher.quickToggleApp()
                    }
                }
            }

            onClosed: {
                appLayer.closed()
                alarmLayerItem.closed()
                topMenuLayerItem.active = false

                if (cameraLayerItem.active) {
                    setCurrentWindow(root.deviceIsLocked
                            ? lockScreenLayerItem.window
                            : homeLayerItem.window)
                } else if (launcherLayerItem.active
                        || lockScreenLayerItem.active) {
                    setCurrentWindow(root.obscuredWindow)
                }
            }

            BlurSource {
                id: peekBlurSource
                anchors.fill: parent

                blur: (topMenuLayer.exposed
                        || launcherLayerItem.exposed
                        || unresponsiveApplicationDialog.windowVisible
                        || root.volumeWarningVisible)
                    && (appLayerItem.opaqueAndMapped
                        || cameraLayerItem.opaqueAndMapped
                        || alarmLayerItem.opaqueAndMapped
                        || dialogLayerItem.opaqueAndMapped
                        || (!root.deviceIsLocked && lockScreenLayer.opaqueAndMapped)
                        || (root.deviceIsLocked && homeLayerItem.currentItem.maximized))

                Item {
                    id: wallpaperWithinPeek

                    anchors.fill: parent
                }

                Item {
                    id: homeWithinPeek

                    anchors.fill: parent
                    visible: root.homeVisible
                }

                BlurSource {
                    id: applicationBlurSource

                    anchors.fill: parent
                    blur: ((alarmLayerItem.exposed && alarmLayerItem.renderDialogBackground)
                           || (dialogLayerItem.exposed && dialogLayerItem.renderDialogBackground))
                            && appLayerItem.opaqueAndMapped

                    ApplicationWallpaper {
                        id: appBgContainer

                        anchors.fill: parent
                        visible: peekLayer.opaque && ((alarmLayerItem.opaque && alarmLayerItem.renderBackground)
                                    || (appLayerItem.opaque && appLayerItem.renderBackground))
                        isLegacyWallpaper: root.isLegacyWallpaper

                        onRotationComplete: {
                            if (appLayerItem.opaque || alarmLayerItem.opaque) {
                                peekBlurSource.update()
                                applicationBlurSource.update()
                            }
                        }
                    }

                    AppLayer {
                        id: appLayerItem

                        background: appBgContainer
                        peekedAt: !launcherLayerItem.opaque
                                    && !topMenuLayerItem.opaque
                                    && !dialogLayerItem.opaque
                                    && !alarmLayerItem.opaque
                                    && (root.showApplicationOverLockscreen || !lockScreenLayerItem.opaque)
                                    && (launcherLayerItem.exposed
                                        || topMenuLayerItem.exposed
                                        || dialogLayerItem.exposed
                                        || alarmLayerItem.exposed
                                        || (!root.showApplicationOverLockscreen && lockScreenLayerItem.exposed))

                        peekingAtHome: peekLayer.peeking
                        closingToHome: peekLayer.closing
                        delaySwitch: homeLayerItem.moving || peekedAt
                        snapshotInUse: alarmLayerItem.renderSnapshot
                                    || dialogLayerItem.renderSnapshot
                                    || lockScreenLayerItem.renderSnapshot
                                    || peekLayer.renderSnapshot
                        windowVisible: peekLayer.exposed && peekLayer.visible

                        peekFilter {
                            leftEnabled: Desktop.startupWizardRunning
                            rightEnabled: Desktop.startupWizardRunning
                            topEnabled: !Desktop.startupWizardRunning && !topMenuLayerItem.active
                            // Minimum top accept margin is 10mm
                            topAcceptMargin: Math.max(QtQuick.Screen.pixelDensity * 10,
                                                      (largeScreen ? (SS.Screen.width - topMenuLayer.exposedArea.width) / 2
                                                                   : Theme.itemSizeMedium))
                        }

                        onAboutToShowWindow: {
                            root.showApplicationOverLockscreen = Desktop.startupWizardRunning
                            homeLayerItem.lastActiveLayer = homeLayerItem.switcher
                            homeLayerItem.setCurrentItem(homeLayerItem.switcher, root.homeVisible)
                        }
                        onCacheWindow: transitionOptimizer.cacheWindow(window)
                        onRequestFocus: {
                            if (root.visible) {
                                root.unlock()
                            }
                        }
                    }

                    ApplicationCloseGestureHint {
                        id: closeGestureHint

                        acceptMargin: appLayerItem.peekFilter.topAcceptMargin
                        opacity: appLayerItem.contentOpacity
                        parent: indicatorApplicationForeground
                        onHintingChanged: appLayerItem.window.fadeEnabled = !hinting
                        active: hintcoordinator.value === 2
                        onActiveChanged: {
                            if (active) {
                                appLayerItem.window.opacity = Qt.binding(function(){
                                    return closeGestureHint.active ? Theme.opacityFaint : 1.0
                                })
                            }
                        }
                    }

                    HintCoordinator {
                        id: hintcoordinator
                        exposed: systemInitComplete && !systemGesturesDisabled
                               && appLayerItem.exposed && !appLayerItem.window.closeHinted
                        window: appLayerItem.window
                    }
                }

                Item {
                    id: lockscreenApplicationForeground
                    anchors.fill: parent

                    BlurSource {
                        id: lockscreenBlurSource

                        blur: ((alarmLayerItem.exposed && alarmLayerItem.renderDialogBackground)
                               || (dialogLayerItem.exposed && dialogLayerItem.renderDialogBackground))
                                && lockScreenLayerItem.opaqueAndMapped
                                && !applicationBlurSource.blur
                                && !root.deviceIsLocked

                        anchors.fill: parent

                        parent: root.deviceIsLocked
                                ? lockscreenHomeForeground
                                : lockscreenApplicationForeground

                        opacity: wallpaperItem.transitioning || ambienceChangeTimeout.running ? 0.0 : 1.0
                        Behavior on opacity { FadeAnimator { duration: 300; alwaysRunToEnd: true } }

                        Item {
                            id: wallpaperBelowLockscreen

                            anchors.fill: parent
                        }

                        LockScreenLayer {
                            id: lockScreenLayerItem

                            screenIsLocked: root.screenIsLocked
                            deviceIsLocked: root.deviceIsLocked
                            background: wallpaperItem
                            renderBackground: true
                            peekedAt: (root.deviceIsLocked && !peekLayer.opaque && peekLayer.exposed)
                                        || ((root.screenIsLocked || cameraLayerItem.exposed)
                                                && !showApplicationOverLockscreen
                                                && !cameraLayerItem.opaque
                                                && !launcherLayerItem.opaque
                                                && !topMenuLayerItem.opaque
                                                && !dialogLayerItem.opaque
                                                && !alarmLayerItem.opaque
                                                && (cameraLayerItem.exposed
                                                    || launcherLayerItem.exposed
                                                    || topMenuLayerItem.exposed
                                                    || dialogLayerItem.exposed
                                                    || alarmLayerItem.exposed))
                            peekingAtHome: !root.deviceIsLocked && peekLayer.peeking
                            delayClose: lockscreenDelayTimer.running
                            onCacheWindow: transitionOptimizer.cacheWindow(window)
                            onClosed: {
                                if (active) {
                                    root.setCurrentWindow(appLayerItem.window || homeLayerItem.window)
                                }
                            }

                            Timer {
                                // Delay the lockscreen fade out until the application has provided a
                                // buffer to render, but don't wait forever.
                                id: lockscreenDelayTimer
                                running: appLayerItem.window && !appLayerItem.window.mapped
                                interval: 2000
                            }
                        }

                        Item {
                            id: notificationLockscreenForeground

                            anchors.fill: parent
                        }
                    }
                }

                CameraLayer {
                    id: cameraLayerItem

                    peekingAtHome: peekLayer.peeking
                    interactiveArea: layersParent.cameraInteractiveArea

                    peekFilter.bottomEnabled: cameraLayerItem.active
                    edgeFilter {
                        enabled: cameraLayerItem.active
                                 || (Desktop.settings.lock_screen_camera
                                     && (screenIsLocked || deviceIsLocked)
                                     && Desktop.deviceLockState <= DeviceLock.Locked)
                    }
                }

                Item {
                    id: dialogApplicationForeground

                    anchors.fill: parent

                    DialogLayer {
                        id: dialogLayerItem

                        parent: peekLayer.peeking ? dialogHomeForeground : dialogApplicationForeground

                        locked: (Desktop.deviceLockState >= DeviceLock.Locked && !Desktop.startupWizardRunning)
                                    || lockScreenLayerItem.pendingPinQuery
                        peekedAt: peekLayer.peeking || (!launcherLayerItem.opaque
                                    && !topMenuLayer.opaque
                                    && !alarmLayerItem.opaque
                                    && (launcherLayerItem.exposed
                                        || topMenuLayerItem.exposed
                                        || alarmLayerItem.exposed))

                        windowVisible: peekLayer.exposed && peekLayer.visible
                        delaySwitch: peekLayer.peeking || !root.completed
                        snapshotInUse: alarmLayerItem.renderSnapshot
                                    || appLayerItem.renderSnapshot
                                    || lockScreenLayerItem.renderSnapshot
                                    || peekLayer.renderSnapshot
                        onCacheWindow: transitionOptimizer.cacheWindow(window)
                    }
                }

                Item {
                    id: alarmApplicationForeground
                    anchors.fill: parent
                }

                AlarmLayer {
                    id: alarmLayerItem

                    parent: alarmApplicationForeground
                    background: appBgContainer
                    peekedAt: (!dialogLayerItem.opaque && dialogLayerItem.exposed)
                              || (!launcherLayerItem.opaque && launcherLayerItem.exposed)
                              || (!topMenuLayerItem.opaque && topMenuLayerItem.exposed)
                    peekingAtHome: peekLayer.peeking
                    closingToHome: peekLayer.closing
                    snapshotInUse: dialogLayerItem.renderSnapshot
                                || appLayerItem.renderSnapshot
                                || lockScreenLayerItem.renderSnapshot
                                || peekLayer.renderSnapshot

                    peekFilter {
                        leftEnabled: Desktop.startupWizardRunning
                        rightEnabled: Desktop.startupWizardRunning
                        topEnabled: !Desktop.startupWizardRunning
                        topAcceptMargin: appLayerItem.peekFilter.topAcceptMargin
                    }

                    windowVisible: (peekLayer.exposed && peekLayer.visible) || root.incomingAlarm
                    onCacheWindow: transitionOptimizer.cacheWindow(window)
                    onAboutToShowWindow: incomingAlarmTimer.stop()
                    onTransitioningChanged: {
                        incomingAlarmTimer.stop()
                        root._resetIncomingAlarm()
                    }
                }

                ShaderEffectSource {
                    /*  This thing merges the application wallpaper and the
                        current frame of the window or alarm. The cache item below
                        is set to live: false, so it doesn't update after this.
                        The result is that we reduce 2x overdraw to 1x which is
                        enough to keep us at 60fps during the transition. We will
                        in all likelyhood skip one frame at the start of the
                        transition though, but this is a price we have to pay for
                        the rest to run ok.
                      */
                    id: transitionOptimizer

                    readonly property Layer transitioningLayer: {
                        if (alarmLayerItem.renderSnapshot) {
                            return alarmLayerItem
                        } else if (dialogLayerItem.renderSnapshot) {
                            return dialogLayerItem
                        } else if (lockScreenLayerItem.renderSnapshot) {
                            return lockScreenLayerItem
                        } else if (appLayerItem.renderSnapshot) {
                            return appLayerItem
                        } else {
                            return peekLayer
                        }
                    }

                    parent: transitioningLayer.transitionItem

                    anchors.fill: parent

                    sourceItem: used ? transitioningLayer.snapshotSource : null
                    hideSource: true
                    live: Desktop.settings.live_snapshots

                    visible: used || transitionOptimizerFadeOut.running
                    opacity: 0
                    property bool suppressFade
                    property bool used: alarmLayerItem.renderSnapshot
                                || dialogLayerItem.renderSnapshot
                                || lockScreenLayerItem.renderSnapshot
                                || appLayerItem.renderSnapshot
                                || peekLayer.renderSnapshot

                    onUsedChanged: {
                        if (used) {
                            transitionOptimizerFadeOut.stop()
                            opacity = 1
                            suppressFade = peekLayer.opaque
                        } else if (!live && !suppressFade && peekLayer.opaque && (alarmLayer.opaque
                                    || dialogLayerItem.opaque
                                    || appLayerItem.opaque)) {
                            transitionOptimizerFadeOut.start()
                        }
                    }

                    function cacheWindow(window) {
                        transitionOptimizerBg.scheduleUpdate()
                        scheduleUpdate()
                        suppressFade = peekLayer.opaque || dialogLayerItem.opaque
                    }

                    SequentialAnimation {
                        id: transitionOptimizerFadeOut
                        FadeAnimator {
                            target: transitionOptimizer
                            from: 1;
                            to: 0
                            duration: 350
                            easing.type: Easing.InOutQuad
                        }
                        PropertyAction { target: transitionOptimizer; property: "visible"; value: false; }
                        running: false
                    }

                    Item {
                        anchors.fill: parent

                        visible: transitionOptimizer.transitioningLayer.renderBackground
                                    && transitionOptimizer.transitioningLayer.renderSnapshot
                        parent: transitionOptimizer.transitioningLayer.underlayItem

                        // Background for peeking and fade-in/out when wallpaper is not exposed.
                        Rectangle {
                            anchors.fill: parent
                            visible: !wallpaper.exposed
                            color: "black"
                        }

                        ShaderEffectSource {
                            id: transitionOptimizerBg
                            sourceItem: transitionOptimizer.used
                                    ? transitionOptimizer.transitioningLayer.background
                                    : null
                            anchors.fill: parent
                            live: Desktop.settings.live_snapshots
                        }
                    }
                }
            }

            RotatingItem {
                id: indicatorApplicationForeground
            }

            LauncherLayer {
                id: launcherLayerItem

                peekingAtHome: peekLayer.peeking
                interactiveArea: layersParent.launcherInteractiveArea

                peekFilter.bottomEnabled: launcherLayerItem.active
                edgeFilter {
                    enabled: launcherLayerItem.active || (systemInitComplete
                                && !root.deviceIsLocked
                                && !cameraLayerItem.active
                                && !topMenuLayerItem.active
                                && (homeLayer.active
                                    || appLayer.active
                                    || alarmLayerItem.inCall
                                    || (!(Desktop.settings.lock_screen_camera && screenIsLocked)
                                        && lockScreenLayerItem.active)))

                    onGestureTriggered: {
                        var window = launcherLayerItem.active
                                ? root.obscuredWindow
                                : launcherLayerItem.window
                        setCurrentWindow(window)
                    }
                }

                onClosed: if (launcherLayerItem.closedFromBottom) launcherEdgeHandle.animate = false
            }

            Rectangle {
                id: displayOffRectangle

                property bool keepVisible
                property bool suppressDisplayOffBehavior

                anchors.fill: parent
                color: "black"

                parent: topMenuLayerItem.peeking || topMenuLayerItem.closing
                        ? topMenuPeekBackground
                        : topMenuStackBackground

                visible: !topMenuLayer.opaque && (topMenuLayerItem.exposed || displayOffAnimation.running)
                opacity: topMenuLayerItem.exposed
                            || keepVisible
                        ? topMenuLayerItem.exposure * Theme.opacityLow
                        : 0.0

                Behavior on opacity {
                    id: displayOffBehavior
                    enabled: !topMenuLayerItem.closing && !displayOffRectangle.suppressDisplayOffBehavior
                    SmoothedAnimation {
                        id: displayOffAnimation
                        duration: 400
                        velocity: -1
                    }
                }
            }

            Item {
                id: topMenuStackBackground
                anchors.fill: parent
            }

            TopMenuLayer {
                id: topMenuLayerItem

                peekingAtHome: peekLayer.peeking
                interactiveArea: layersParent.topMenuInteractiveArea
                active: false
                peekFilter {
                    topEnabled: topMenuLayerItem.active && !launcherHinting
                    leftEnabled: peekFilter.topEnabled
                    rightEnabled: peekFilter.topEnabled
                    onGestureStarted: displayOffRectangle.keepVisible = true
                    onGestureCanceled: displayOffRectangle.keepVisible = false
                    onGestureTriggered: {
                        displayOffRectangle.suppressDisplayOffBehavior = true
                        if (closeFromEdge) topmenuEdgeHandle.earlyFadeout = true
                    }
                }
                edgeFilter {
                    enabled: !launcherHinting
                             && DeviceLock.state <= DeviceLock.Locked
                             && (topMenuLayerItem.active
                                 || homeLayer.active
                                 || appLayerItem.active
                                 || alarmLayerItem.inCall
                                 || lockScreenLayerItem.active)

                    topRejectMargin: !Desktop.startupWizardRunning
                                && (appLayerItem.active || alarmLayerItem.inCall)
                            ? Theme.itemSizeMedium
                            : 0

                    onGestureStarted: {
                        if (!topMenuLayerItem.active) {
                            displayOffRectangle.suppressDisplayOffBehavior = false
                            root.powerKeyPressed = false
                        }
                    }

                    onGestureTriggered: {
                        // TopMenu should not steal focus, so just set active instead of making it
                        // the current window.
                        topMenuLayerItem.active = !topMenuLayerItem.active
                    }
                }

                onToggleActive: {
                    topMenuLayerItem.active = !topMenuLayerItem.active
                    displayOffRectangle.suppressDisplayOffBehavior = false
                }

                onExposedChanged: if (exposed) topmenuEdgeHandle.earlyFadeout = false
                onClosed: {
                    displayOffRectangle.keepVisible = false
                    topmenuEdgeHandle.earlyFadeout = false
                }

                Item {
                    id: topMenuPeekBackground
                    anchors.fill: parent
                }
            }
        }

        OverlayLayer {
            id: overlayLayer
        }
    }

    Item {
        id: alarmLayersForeground
        anchors.fill: parent
    }

    Item {
        id: notificationLayer

        property alias contentItem: notificationLayer

        anchors.fill: parent

        Binding {
            target: root
            when: notificationLayer.children.length > 0
            property: "statusBarPushDownY"
            value: {
                var pushDown = 0
                for (var i = 0; i < notificationLayer.children.length; ++i) {
                    var item = notificationLayer.children[i]
                    var rootItem = item && item.window && item.window.rootItem
                    if (rootItem && rootItem.hasOwnProperty("statusBarPushDownY"))
                        pushDown = Math.max(pushDown, rootItem.statusBarPushDownY)
                }
                return pushDown
            }
        }
    }

    Component {
        id: windowWrapper
        WindowWrapper { }
    }

    Component {
        id: inProcWindowWrapper
        InProcWindowWrapper { }
    }

    onWindowAdded: {
        if (debug) {
            console.debug("Compositor: Window added \"" + window.title + "\"")
        }

        if (window.category == "cover" || window.category == "silica-cover") {
            window.visible = false
            return
        }

        if (!window.isInProcess && (window.category == "" || window.category == "partner")) {
            var partnerLayer = homeLayer.partnerLayerForWindow(window)
            if (partnerLayer) {
                partnerLayer.window.window = window
                window.userData = partnerLayer.window
                window.parent = partnerLayer.window
                window.visible = true
                if (partnerLayer.maximized) {
                    window.forceActiveFocus()
                }
                return
            }
        }

        if (!window.isInProcess && JollaSystemInfo.isWindowForLauncherItem(window, cameraLayerItem.application)) {
            cameraLayerItem.window.window = window
            window.userData = cameraLayerItem.window
            window.parent = cameraLayerItem.window
            window.visible = true
            window.focus = true

            updateWindows(false)

            return
        }

        var isHomeWindow = window.isInProcess && homeLayer.window == null && window.title == "Home"
        var isLockScreenWindow = window.isInProcess && window.title == "Lock Screen"
        var isLauncherWindow = window.isInProcess && window.title == "Launcher"
        var isShutdownWindow = window.isInProcess && window.title == "Shutdown"
        var isTopMenuWindow = window.isInProcess && window.category == "topmenu"
        var isEventsWindow = window.isInProcess && window.category == "events"
        var isDialogWindow = window.category == "dialog"
        var isNotificationWindow = window.category == "notification"
        var isOverlayWindow = window.category == "overlay"
        var isAlarmWindow = window.category == "alarm" || window.category == "call"
        var isApplicationWindow = window.category == "" || window.category == "silica"

        var type = WindowType.Internal
        var component = null;
        if (window.isInProcess) component = inProcWindowWrapper
        else component = windowWrapper

        var parent = null
        var parentItem = null
        if (isHomeWindow) {
            parent = homeLayerItem.switcher
            parentItem = homeLayerItem.switcher.contentItem
        } else if (isEventsWindow) {
            parent = homeLayerItem.events
            parentItem = homeLayerItem.events.contentItem
        } else if (isLockScreenWindow) {
            parent = lockScreenLayer
            parentItem = lockScreenLayerItem.contentItem
        } else if (isLauncherWindow) {
            parent = launcherLayer
            parentItem = launcherLayerItem.contentItem
        } else if (isShutdownWindow) {
            parent = shutdownLayer
            parentItem = shutdownLayer.contentItem
        } else if (isTopMenuWindow) {
            parent = topMenuLayerItem
            parentItem = topMenuLayerItem.contentItem
        } else if (isDialogWindow) {
            parent = dialogLayer
            type = WindowType.Dialog
        } else if (isNotificationWindow) {
            parent = notificationLayer
            if (!onlyCurrentNotificationAllowed) {
                parentItem = notificationLayer.contentItem
            }
        } else if (isOverlayWindow) {
            parent = overlayLayer
            parentItem = overlayLayer.contentItem
        } else if (isAlarmWindow) {
            parent = alarmLayer
            type = WindowType.Alarm
        } else if (isApplicationWindow) {
            type = WindowType.Application
            parent = appLayer
        } else {
            console.warn("Compositor: Unidentified", window.category, "window added \"" + window.title + "\"")
            window.visible = false
            if (window.surface !== undefined) {
                window.surface.visibility = Window.Hidden
            }
            return
        }

        window.focusOnTouch = !window.isInProcess && !isOverlayWindow && !isNotificationWindow

        // reparenting already handled (window is transient to another window)
        if (isApplicationWindow && window.parent !== root.contentItem) {
            return
        }

        var w = component.createObject(parent, {
            'window': window,
            'parent': parentItem,
            'windowType': type
        })

        if (debug) {
            w.objectName = "windowFor_" + parent.objectName
        }
        window.userData = w

        if (parentItem) {
            w.exposed = Qt.binding(function () { return parentItem.visible })
        }

        if (isHomeWindow) {
            homeLayerItem.switcher.window = w
            launcherLayer.allowed = true
            desktop = Desktop.instance
        } else if (isLockScreenWindow) {
            lockScreenLayer.window = w
            setCurrentWindow(lockScreenLayer.window)
        } else if (isLauncherWindow) {
            launcherLayer.window = w
        } else if (isTopMenuWindow) {
            topMenuLayerItem.window = w
        } else if (isEventsWindow) {
            homeLayerItem.events.window = w
        } else if (isDialogWindow) {
            dialogLayer.quickShow(w)
        } else if (isOverlayWindow) {
            w.z = 1
            // Force notification of clipboard changes to keyboard
            window.surface.updateSelection()
            root.clipboard.dataChanged.connect(window.surface.updateSelection)
        } else if (isNotificationWindow) {
        } else if (isAlarmWindow) {
            if (!root.visible) {
                prepareToShowAlarm()
            }
            alarmLayer.quickShow(w)
        } else if (isApplicationWindow) {
            appLayerItem.quickShow(w)
        } else {
            console.warn("Compositor:", window.category, "window \"" + window.title + "\" not assigned a layer")
        }

        updateWindows(isNotificationWindow)
    }

    onWindowRemoved: {
        if (debug) console.debug("\nCompositor: Window removed \"" + window.title + "\"")

        var w = window.userData;

        if (!w) {
            return
        }

        switch (w.windowType) {
        case WindowType.Alarm:
            alarmLayerItem.hide(w, true)
            break
        case WindowType.Dialog:
            dialogLayerItem.hide(w, true)
            break
        case WindowType.Application:
            appLayerItem.hide(w, true)
            break
        case WindowType.PartnerSpace:
            homeLayerItem.partnerWindowRemoved(w)
            break
        case WindowType.Camera:
            cameraLayerItem.close()
            break
        }

        if (topmostWindow == w) {
            setCurrentWindow(root.obscuredWindow);
        }

        var closingIndex = windowsBeingClosed.indexOf(window.userData)
        if (closingIndex >= 0) {
            var newWindowsBeingClosed = windowsBeingClosed
            newWindowsBeingClosed.splice(closingIndex, 1)
            windowsBeingClosed = newWindowsBeingClosed
        }

        if (w.windowType != WindowType.PartnerSpace && w.windowType != WindowType.Camera) {
            w.parent = null
            w.destroy()
        }
    }

    onWindowRaised: raiseWindow(window)
    onWindowLowered: {
        switch (window.userData ? window.userData.windowType : WindowType.Internal) {
        case WindowType.Alarm:
            alarmLayerItem.hide(window.userData)
            break
        case WindowType.Dialog:
            dialogLayerItem.hide(window.userData)
            break
        case WindowType.Application:
            appLayerItem.hide(window.userData)
            break
        case WindowType.PartnerSpace:
            homeLayerItem.partnerWindowLowered(window.userData)
            break;
        case WindowType.Camera:
            cameraLayerItem.close()
            break
        }
    }
    onWindowHidden: {
        if (window.category == "cover" || window.category == "silica-cover")
            return

        // Setting a window visibility Hidden will cause a surface unmap
        if (window.userData && window.userData.ignoreHide) {
            window.userData.ignoreHide = false
            return
        }

        windowLowered(window)
    }

    onShowUnlockScreen: {
        if (!root.visible) {
            showDeviceLock = true
        } else if (root.deviceIsLocked && !cameraLayerItem.active) {
            root.unlock()
        }
    }
    onDisplayOn: showDeviceLock = false

    onDisplayAboutToBeOn: {
        _displayOn = true
        if (lipstickSettings.blankingPolicy == "call" || lipstickSettings.blankingPolicy == "alarm") {
            prepareToShowAlarm()
        }
    }

    onDisplayAboutToBeOff: {
        if (lipstickSettings.blankingPolicy == "call" || lipstickSettings.blankingPolicy == "alarm") {
            currentAlarm = true
        }
    }

    onDisplayOff: {
        _displayOn = false
        root.PeekFilter.cancelGesture()
        displayOffAnimation.complete()
        showDeviceLock = false
        showApplicationOverLockscreen = Desktop.startupWizardRunning
        topMenuLayerItem.active = false

        if ((lipstickSettings.lockscreenVisible || cameraLayerItem.active)
                && !Desktop.startupWizardRunning) {
            setCurrentWindow(lockScreenLayerItem.window)
        }
    }

    onActiveFocusItemChanged: {
        if (activeFocusItem && isLipstickCompositorWindow(activeFocusItem)) {
            activeFocusItem.takeFocus() // send wl_keyboard.enter
        } else if (activeFocusItem != contentItem) {
            // Clear wayland keyboard focus if a non-compositor window item has focus.
            // If the Window content item has focus no item in the scene does indicating some
            // part of the scene is disabled. This is a transitory state and shouldn't propagate
            // to the application.
            clearKeyboardFocus()
        }
    }

    Timer {
        id: incomingAlarmTimer
        interval: 2000
        onTriggered: root._resetIncomingAlarm()
    }

    Connections {
        target: lipstickSettings
        onBlankingPolicyChanged: currentAlarm = false
    }

    UnresponsiveApplicationDialog {
        id: unresponsiveApplicationDialog
        window: root.windowsBeingClosed.length > 0 ? root.windowsBeingClosed[0].window
                                                   : (appLayer.window ? appLayer.window.window : null)
    }

    TouchBlocker {
        id: shutdownLayerItem

        property alias contentItem: shutdownLayerItem
        anchors.fill: parent
        enabled: children.length > 0
    }

    ConfigurationGroup {
        id: keymapConfig

        path: "/desktop/lipstick-jolla-home"

        property string rules: "evdev"
        property string model: "jollasbj"
        property string layout: "us"
        property string variant: ""
        property string options: ""
    }

    NemoDBus.DBusInterface {
        service: 'com.jolla.keyboard'
        path: '/com/jolla/keyboard'
        iface: 'com.jolla.keyboard'
        signalsEnabled: true
        watchServiceStatus: true

        function keyboardHeightChanged(keyboardHeight) {
            root.PeekFilter.keyboardHeight = keyboardHeight
        }
    }

    NemoDBus.DBusInterface {
        bus: NemoDBus.DBus.SystemBus
        service: 'com.nokia.mce'
        path: '/com/nokia/mce/signal'
        iface: 'com.nokia.mce.signal'
        signalsEnabled: true

        function fader_opacity_ind(opacityPercent, duration) {
            /* Note: The new duration must be in place before opacity
             *       change or the fade animation could start using
             *       the previous duration, i.e. we must explicitly
             *       set the object values in correct order instead
             *       of doing implicit evaluation at objects. */
            dimmingAnimation.duration = duration
            dimmingRectangle.opacity  = opacityPercent * 0.01
        }

        function power_button_trigger(argument) {
            if (argument === "double-power-key") {
                root.showUnlockScreen()
            } else if (argument === "home-key") {
                if (!root.systemGesturesDisabled) {
                    root.goToSwitcher(true)
                }
            }
        }
    }

    Rectangle {
        id: dimmingRectangle
        anchors.fill: parent
        color: "black"
        opacity: 0.0
        visible: opacity > 0.05
        Behavior on opacity {
            FadeAnimation { id: dimmingAnimation  }
        }
    }

    Loader {
        id: debugWindow
        active: root.debug
        z: 10
        anchors.fill: parent
        sourceComponent: DebugWindow { compositor: root }
    }

    Loader {
        active: deviceInfo.hasHardwareKey(Qt.Key_HomePage)
        source: "compositor/HardwareKeyHandler.qml"
        DeviceInfo {
            id: deviceInfo
        }
    }
}
