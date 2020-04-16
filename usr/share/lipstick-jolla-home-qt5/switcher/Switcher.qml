/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import org.nemomobile.lipstick 0.1
import org.nemomobile.ngf 1.0
import com.jolla.lipstick 0.1
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Lipstick 1.0
import "../compositor"
import "../main"

SilicaFlickable {
    id: switcherRoot

    readonly property int showingWid: Lipstick.compositor.appLayer.pendingWindowId
    property Item launchingItem
    property bool skipOnReleased: false
    readonly property bool appShowInProgress: showingWid > 0
                || (launchingItem && launchingItem.launching && !launchingItem.minimized)
    property real statusBarHeight: Lipstick.compositor.homeLayer.statusBar.height
    readonly property real count: repeater.count
    readonly property bool largeScreen: Screen.sizeCategory >= Screen.Large
    property bool housekeeping: false
    property bool menuOpen: housekeepingMenu.active

    property alias model: switcherModel

    property int secondLastAppIndex

    readonly property bool switcherVisible: Lipstick.compositor && Lipstick.compositor.switcherLayer.visible
    onSwitcherVisibleChanged: {
        if (!switcherVisible) {
            housekeeping = false
            // The view is completely hidden. The delay is a grace period, so
            // that if you quickly exit and reenter the view has not moved.
            resetPosition(300)
        } else {
            cancelResetPosition()
        }
        if (columnUpdateTimer.running) {
            columnUpdateTimer.stop()
            switcherGrid.doUpdateColumns()
        }
        columnChangeAnimation.complete()
    }

    contentHeight: Math.ceil(switcherWrapper.y + switcherWrapper.height)

    interactive: contentHeight > height || housekeeping

    onHousekeepingChanged: {
        minimizeLaunchingWindows()
        switcherGrid.updateColumns()
    }

    function minimizeLaunchingWindows() {
        for (var i = 0; i < repeater.count; ++i) {
            var item = repeater.itemAt(i)
            if (item.launching)
                item.minimized = true
        }
        Lipstick.compositor.appLayer.clearPendingWindows()
    }

    function activateWindowFor(launcherItem, launch) {
        if (Desktop.startupWizardRunning)
            return

        minimizeLaunchingWindows()

        var item
        var index = windowIndexOf(launcherItem)
        var singleInstance = launcherItem.readValue("X-Nemo-Single-Instance")
        if (index >= 0  && singleInstance !== "no") {
            item = repeater.itemAt(index)
            item.minimized = false

            ensureVisible(item)

            Lipstick.compositor.goToApplication(item.windowId)

            launcherItem.isLaunching = false
        } else if (!Lipstick.compositor.homeLayer.activatePartnerWindow(launcherItem, launch)) {

            // We don't know if D-Bus method call will create a new process, let the respective service handle the loading cover
            var dBusActivationOnly = launcherItem.exec.length === 0 && launcherItem.dBusActivated
            if (launcherItem.shouldDisplay && launcherItem.entryType == "Application" && !dBusActivationOnly) {
                var switcherIndex = switcherModel.findInactiveCover(launcherItem)
                if (switcherIndex >= 0) {
                    item = repeater.itemAt(switcherIndex)
                    item.launching = true
                    item.minimized = false
                    launchingItem = item

                    ensureVisible(item)
                } else {
                    switcherModel.append(launcherItem)
                }
                Lipstick.compositor.goToSwitcher(true)
            }
            if (launcherItem.entryType == "Link") {
                // Just close the launcher, application handles raising the window
                Lipstick.compositor.launcherLayer.hide()
            }
            if (launch) {
                launcherItem.launchApplication()
            }
            if (dBusActivationOnly) {
                launcherItem.isLaunching = false
            }
        }
    }

    function checkMinimized(wid) {
        for (var i = 0; i < repeater.count; ++i) {
            var item = repeater.itemAt(i)
            if ((item.running && item.windowId == wid)
                        || (!item.running && isWindowIdFor(wid, item.launcherItem))) {
                if (item.minimized) {
                    item.minimized = false
                    return true
                } else {
                    return false
                }
            }
        }
        return false
    }

    function closeCover(launcherItem) {
        var index = model.findCover(launcherItem)
        if (index >= 0 && index < repeater.count) {
            var item = repeater.itemAt(index)
            item.close()
        }
    }

    property bool closePending
    property bool housekeepingMenuActive: housekeepingMenu.active
    onHousekeepingMenuActiveChanged: {
        if (!housekeepingMenuActive && closePending) {
            closePending = false
            closeAll()
        }
    }

    onMovementStarted: minimizeLaunchingWindows()

    PullDownMenu {
        id: housekeepingMenu
        visible: switcherRoot.housekeeping

        MenuItem {
            //: Menu item in pull down menu, closes all open applications
            //% "Close all"
            text: qsTrId("lipstick-jolla-home-me-close_all")
            onClicked: closePending = true
        }
    }

    Timer {
        id: closeAllTimer
        property int lastIndex

        interval: 100
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            if (repeater.count === 0 || lastIndex === 0) {
                running = false
                return
            }

            lastIndex = lastIndex - 1
            if (lastIndex > repeater.count - 1) {
                lastIndex = repeater.count - 1
            }

            repeater.itemAt(lastIndex).close()
        }
    }

    function closeAll() {
        closeAllTimer.stop()
        closeAllTimer.lastIndex = repeater.count
        closeAllTimer.start()
    }

    function isAndroidApplication(launcherItem) {
        return launcherItem.readValue("X-apkd-apkfile") != ""
    }

    function windowIndexOf(launcherItem) {
        if (mruSwitcherModel.count == 0)
            return -1
        // Try to determine whether the app is currently minimized by matching
        // the command used to start it with the apps we're managing.
        var cmd = launcherItem.exec

        var pids = {}
        var appId
        var isAndroid = isAndroidApplication(launcherItem)
        if (isAndroid) {
            var pkg = cmd.split(' ')[2]
            appId = pkg.split('/')[0]
        }

        for (var i = 0; i < switcherModel.itemCount; i++) {
            var window = Lipstick.compositor.windowForId(switcherModel.windowId(i))
            if (!window) {
                // Process was probably OOMed
            } else if (isAndroid) {
                var id = window.surface.className
                if (appId == id) {
                    return i
                }
            } else {
                pids[window.processId] = i
            }
        }

        if (isAndroid)
            return -1

        var pid = JollaSystemInfo.matchingPidForCommand(Object.keys(pids), cmd, false)
        return pid >= 0 ? pids[pid] : -1
    }

    function isWindowIdFor(wid, launcherItem) {
        return JollaSystemInfo.isWindowForLauncherItem(Lipstick.compositor.windowForId(wid), launcherItem)
    }

    function touchWindow(windowId) {
        var windowFound = false
        for (var i = 0; i < mruSwitcherModel.count; i++) {
            var modelIdx = mruSwitcherModel.mapRowToSource(i)
            var mappedWindowId = switcherModel.windowId(modelIdx)

            var switcherItem
            if (modelIdx >= 0) {
                switcherItem = repeater.itemAt(modelIdx)
            }

            if (mappedWindowId == windowId || (switcherItem && switcherItem.windowId == windowId)) {
                mruSwitcherModel.touch(i)
                windowFound = true
                break
            }
        }

        // Update 2nd last application.
        if (mruSwitcherModel.count > 1)
            secondLastAppIndex = mruSwitcherModel.mapRowToSource(1)
        else
            secondLastAppIndex = -1

        return windowFound ? modelIdx : -1
    }

    function quickToggleApp() {
        if (secondLastAppIndex >= 0) {
            var item = repeater.itemAt(secondLastAppIndex)
            item.minimized = false
            ensureVisible(item)

            Lipstick.compositor.goToApplication(item.windowId)

            var launcherItem = item.launcherItem
            launcherItem.isLaunching = false
        }
    }

    function launchingCount() {
        var count = 0
        for (var i = 0; i < repeater.count; ++i) {
            if (repeater.itemAt(i) && repeater.itemAt(i).launching) {
                count++
            }
        }

        return count
    }

    Connections {
        target: Lipstick.compositor
        onMinimizeLaunchingWindows: switcherRoot.minimizeLaunchingWindows()
        onTopmostWindowIdChanged: touchWindow(Lipstick.compositor.topmostWindowId)
    }

    function resetPosition(delay) {
        resetPositionTimer.interval = delay === undefined ? 1 : delay
        resetPositionTimer.restart()
    }
    function cancelResetPosition() {
        resetPositionTimer.stop()
    }

    Timer {
        id: resetPositionTimer
        onTriggered: switcherRoot.contentY = switcherRoot.originY
    }

    function playEffect() {
        ngfEvent.play()
    }

    NonGraphicalFeedback {
        id: ngfEvent
        event: "pulldown_highlight"
    }

    function ensureVisible(item) {
        ensureVisibleTimer.item = item
        ensureVisibleTimer.start()
    }

    Timer {
        id: ensureVisibleTimer
        property Item item
        interval: 1
        onTriggered: {
            Lipstick.compositor.topMenuLayer.hide()
            if (columnChangeAnimation.running) {
                return
            } else if (item.y < contentY) {
                scrollAnimation.to = item.y
                scrollAnimation.duration = 150
                scrollAnimation.start()
            } else if (item.y + item.height + switcherWrapper.y + switcherGrid.rowSpacing > contentY + height) {
                var to = Math.min(item.y + item.height + switcherGrid.rowSpacing, switcherWrapper.height) + switcherWrapper.y - height
                if (to >= 0) {
                    scrollAnimation.to = to
                    scrollAnimation.duration = 150
                    scrollAnimation.start()
                }
            }
        }
    }

    NumberAnimation {
        id: scrollAnimation
        target: switcherRoot
        property: "contentY"
        easing.type: Easing.InOutQuad
    }

    function scroll(up) {
        scrollAnimation.to = up ? 0 : contentHeight - height
        scrollAnimation.duration = Math.abs(contentY - scrollAnimation.to) * 1.5
        scrollAnimation.start()
    }

    function stopScrolling() {
        scrollAnimation.stop()
    }

    VerticalScrollDecorator {
        visible: Lipstick.compositor.switcherLayer.scale === 1.0 && switcherRoot.contentHeight > switcherRoot.height
    }

    MouseArea {
        id: switcherWrapper

        objectName: "Switcher_wrapper"

        y: switcherGrid.baseY
        height: switcherGrid.implicitHeight <= switcherRoot.height - y
                ? switcherRoot.height - y
                : switcherGrid.implicitHeight + switcherGrid.rowSpacing - 1
        width: switcherRoot.width

        onWidthChanged: switcherGrid.updateColumns()

        SwitcherGrid {
            id: switcherGrid

            columns: largeColumns
            statusBarHeight: switcherRoot.statusBarHeight

            readonly property bool allowSmallCovers: !largeScreen
            readonly property int largeItemCount: largeColumns * largeRows

            property QtObject ngfEffect

            function updateColumns() {
                // use a timer since switcherModel and pendingWindows models aren't in sync.
                if (!switcherRoot.housekeeping) {
                    if (switcherRoot.switcherVisible) {
                        columnUpdateTimer.restart()
                    } else {
                        doUpdateColumns()
                    }
                }
            }

            function doUpdateColumns() {
                var cols = switcherGrid.largeColumns
                if (switcherGrid.allowSmallCovers && switcherModel.itemCount > switcherGrid.largeItemCount)
                    cols = switcherGrid.smallColumns
                if (cols !== switcherGrid.columns) {
                    scrollAnimation.stop()
                    if (desktop.orientationTransitionRunning || !switcherRoot.switcherVisible) {
                        switcherGrid.columns = cols
                        switcherGrid.coverSize = switcherGrid.columns == switcherGrid.largeColumns ? Theme.coverSizeLarge : Theme.coverSizeSmall
                    } else {
                        columnChangeAnimation.restart()
                    }
                }
            }

            Timer {
                id: columnUpdateTimer
                interval: 1
                onTriggered: switcherGrid.doUpdateColumns()
            }

            SequentialAnimation {
                id: columnChangeAnimation
                NumberAnimation { target: switcherItems; property: "opacity"; to: 0.0; duration: 200 }
                ScriptAction {
                    script: {
                        var cols = switcherGrid.largeColumns
                        if (switcherGrid.allowSmallCovers && switcherModel.itemCount > switcherGrid.largeItemCount)
                            cols = switcherGrid.smallColumns
                        switcherGrid.columns = cols
                        switcherGrid.coverSize = switcherGrid.columns == switcherGrid.largeColumns ? Theme.coverSizeLarge : Theme.coverSizeSmall
                        switcherRoot.contentY = 0
                    }
                }
                NumberAnimation { target: switcherItems; property: "opacity"; to: 1.0; duration: 200 }
            }

            EditableGridManager {
                id: gridManager
                view: switcherGrid
                pager: switcherRoot
                contentContainer: switcherItems
                function itemAt(x, y) {
                    return switcherGrid.childAt(x, y)
                }
                function itemCount() {
                    return repeater.count
                }
                onScroll: switcherRoot.scroll(up)
                onStopScrolling: switcherRoot.stopScrolling()
            }

            MruSortedModel {
                id: mruSwitcherModel
                model: PersistentSwitcherModel {
                    id: switcherModel

                    model: SwitcherModel {
                        partnerspaces: Lipstick.compositor.homeLayer.partnerspaces
                        excludedItems: [
                            Lipstick.compositor.cameraLayer.application
                        ]
                    }
                }
                onRowsMoved: switcherWrapper.adjustOOMScores()
                onCountChanged: switcherWrapper.adjustOOMScores()
            }

            Repeater {
                id: repeater

                model: switcherModel

                delegate: SwitcherItem {
                    id: switcherDelegate
                    manager: gridManager
                    width: switcherGrid.coverSize.width
                    height: switcherGrid.coverSize.height

                    windowId: (model.window ? applicationWindowId.value : undefined) || model.window || 0
                    onWindowIdChanged: {
                        if (windowId != 0) {
                            touchWindow(windowId)
                            switcherWrapper.adjustOOMScores()
                        }
                    }

                    onQuickSwitchingAppChanged: {
                        if (quickSwitchingApp && switcherGrid.ngfEffect) {
                            switcherGrid.ngfEffect.play()
                        }
                    }

                    running: model.running
                    pending: model.pending
                    launcherItem: model.launcherItem

                    onRunningChanged: {
                        if (running && launcherItem) {
                            launcherItem.isLaunching = false
                        }
                    }

                    showingWid: switcherRoot.showingWid
                    columns: switcherGrid.columns
                    animateMovement: switcherRoot.switcherVisible
                                && !columnChangeAnimation.running
                                && !desktop.orientationTransitionRunning

                    processId: model.processId

                    onClicked: {
                        if (switcherRoot.housekeeping) {
                            switcherRoot.housekeeping = false
                        } else if (running) {
                            switcherRoot.minimizeLaunchingWindows()
                            minimized = false
                            Lipstick.compositor.windowToFront(windowId)
                        } else if (launcherItem) {
                            switcherRoot.minimizeLaunchingWindows()
                            // App is not running. Launch it now.
                            launching = true
                            minimized = false
                            switcherRoot.launchingItem = switcherDelegate
                            launcherItem.launchApplication()
                        }
                    }

                    onPressAndHold: switcherRoot.housekeeping = true

                    WindowProperty {
                        id: coverWindowId
                        windowId: model.window || 0
                        property: "SAILFISH_COVER_WINDOW"
                        onValueChanged: {
                            if (model.window) {
                                switcherDelegate.coverId = value || 0
                            }
                        }
                    }
                    WindowProperty {
                        windowId: model.window || 0
                        property: "SAILFISH_RETAIN_COVER"
                        onValueChanged: {
                            if (value !== undefined) {
                                switcherModel.setRetainCover(index, value)
                            }
                        }
                    }
                    WindowProperty {
                        windowId: model.window || 0
                        property: "SAILFISH_HAVE_COVER"
                        onValueChanged: {
                            switcherDelegate.coverHint = value || false
                        }
                    }
                    WindowProperty {
                        id: applicationWindowId
                        windowId: model.window || 0
                        property: "SAILFISH_APPLICATION_WINDOW"
                    }
                }

                onCountChanged: {
                    if (count == 0 && switcherRoot.housekeeping) {
                        switcherRoot.housekeeping = false
                    }
                    switcherGrid.updateColumns()
                }

                onItemAdded: {
                    if (item.launching) {
                        switcherRoot.launchingItem = item
                    }
                    switcherRoot.ensureVisible(item)
                }
            }

            Connections {
                target: Lipstick.compositor.appLayer
                onWindowShown: switcherModel.cleanupPending()
            }

            Binding {
                target: Lipstick.compositor.homeLayer
                property: "statusMargin"
                value: switcherWrapper.y
            }

            Component.onCompleted: {
                // avoid hard dependency to ngf module
                ngfEffect = Qt.createQmlObject("import org.nemomobile.ngf 1.0; NonGraphicalFeedback { event: 'push_gesture' }",
                                                switcherGrid, 'NonGraphicalFeedback')
            }
        }

        // We use a separate inner item here instead of reparenting to switcherWrapper
        // to allow the column change animation to modify its opacity without interfering
        // with any opacity applied to switcherWrapper.
        Item {
            id: switcherItems
            anchors.fill: switcherGrid

            // MouseArea doesn't propagate the enabled state to children, so do it manually
            // https://bugreports.qt-project.org/browse/QTBUG-38364
            enabled: parent.enabled
        }

        property real pressPos
        onPressAndHold: {
            // don't enter housekeeping mode with launcher is hinting, no windows open, or when not in switcher
            if (Lipstick.compositor.launcherHinting || mruSwitcherModel.count == 0
                    || Math.abs(pressPos - mouse.y) > Theme.startDragDistance)
                return

            switcherRoot.housekeeping = !switcherRoot.housekeeping
            switcherRoot.minimizeLaunchingWindows()
        }

        onPressed: pressPos = mouse.y
        onClicked: {
            var wasHousekeeping = switcherRoot.housekeeping
            if (switcherRoot.housekeeping && !switcherRoot.housekeepingMenuActive)
                switcherRoot.housekeeping = false
            else if (!wasHousekeeping)
                Lipstick.compositor.launcherHinting = true
        }

        function adjustOOMScores() {
            var oomScore = 0
            for (var i = 0; i < mruSwitcherModel.count; i++) {
                if (i == 0) {
                    oomScore = 0 // most recently used
                } else {
                    oomScore = 69 + i
                }
                JollaSystemInfo.adjustOOMScore(oomScore, Lipstick.compositor.windowForId(switcherModel.windowId(mruSwitcherModel.mapRowToSource(i))))
            }
        }
    }
    CloseAllAppsHint {}
}
