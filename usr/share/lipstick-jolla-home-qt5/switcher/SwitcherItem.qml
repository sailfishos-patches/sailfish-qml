/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import QtQuick.Window 2.1 as QtQuick
import org.nemomobile.lipstick 0.1
import org.nemomobile.ngf 1.0
import com.jolla.coveractions 0.1
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Lipstick 1.0
import "../compositor"
import "../main"

EditableGridDelegate {
    id: wrapper
    property bool currentApp: windowId != 0 && Lipstick.compositor.topmostWindowId == windowId
    readonly property bool quickSwitchingApp: index == secondLastAppIndex && Lipstick.compositor.quickAppToggleGestureExceeded
    property int coverId
    readonly property Item cover: Lipstick.compositor.windowForId(wrapper.coverId)
    property int windowId
    readonly property Item window: Lipstick.compositor.windowForId(wrapper.windowId)
    property bool coverHint
    property int processId
    property var launcherItem
    property bool windowMapPending
    property int showingWid
    property int columns: 1
    property bool closing: windowId != 0 && windowId == Lipstick.compositor.appLayer.closingWindowId
    property bool running
    property bool launching: pending
    property bool pending
    property bool minimized
    property bool _persistHousekeeping
    property bool _appTransitioning: currentApp && Lipstick.compositor.appLayer.transitioning

    editMode: switcherRoot.housekeeping

    visible: true
    opacity: 1.0

    onReorder: {
        if (newIndex != -1 && newIndex !== index) {
            switcherModel.move(index, newIndex)
        }
    }

    on_AppTransitioningChanged: {
        if (!_appTransitioning) {
            startupTimer.stop()
        }
    }

    onRunningChanged: {
        if (running) {
            launching = false
        }
    }

    onLaunchingChanged: {
        if (!launching) {
            startupTimer.restart()
        }
    }
    onCoverIdChanged: {
        if (coverId) {
            startupTimer.restart()
        }
    }

    readonly property size coverSize: Qt.size(width, height)

    onCoverSizeChanged: {
        if (cover && cover.surface) {
            cover.surface.requestSize(coverSize)
        }
    }

    onColumnsChanged: {
        cancelAnimation()
        contentItem.opacity = 1.0
        contentItem.x = x
        contentItem.y = offsetY
        _oldY = y
        _viewWidth = manager.view.width
    }

    enabled: !closeAnimation.running


    onVisibleChanged: applyVisibility()

    function applyVisibility() {
        if (cover && cover.surface) {
            cover.surface.visibility = visible ? QtQuick.Window.Minimized : QtQuick.Window.Hidden
        } else if (window && window.userData) {
            window.userData.coverVisibility = visible ? QtQuick.Window.Minimized : QtQuick.Window.Hidden
        }
    }

    onCoverChanged: {
        if (cover && cover.surface) {
            cover.surface.requestSize(coverSize)
        }
        applyVisibility()
    }

    function close() {
        _persistHousekeeping |= switcherRoot.housekeeping
        closeAnimation.start()
    }

    onShowingWidChanged: {
        windowMapPending = wrapper.windowId != 0 && wrapper.windowId === showingWid
        if (windowMapPending) {
            switcherRoot.ensureVisible(wrapper)
        }
    }

    Connections {
        target: wrapper.currentApp ? Lipstick.compositor : null
        ignoreUnknownSignals: true
        onHomePeekingChanged: {
            if (Lipstick.compositor.homePeeking && !wrapper.closing) {
                contentItem.opacity = 0.0
                homePeekAnimation.restart()
            }
        }
    }
    SequentialAnimation {
        id: homePeekAnimation
        PauseAnimation { duration: 200 }
        FadeAnimation {
            target: contentItem
            duration: 400
            to: 1.0
        }
    }

    property bool hideCover: wrapper.launching || startupTimer.running || !windowPixmap.hasPixmap
    property real coverOpacity: hideCover ? 0.0 : (!running ? Theme.opacityHigh : 1.0)

    CoverActionModel {
        id: coverActionModel
        window: model.window
    }

    GlassBackground {
        z: -1
        anchors.fill: parent
        visible: (cover
                ? cover.surface && cover.surface.windowProperties.TRANSPARENT
                : window
                    && window.surface
                    && window.surface.windowProperties.BACKGROUND_VISIBLE !== undefined
                    && window.surface.windowProperties.BACKGROUND_VISIBLE) || !running || startupTimer.running || coverOpacityAnimation.running
        radius: windowPixmap.radius
    }

    WindowPixmapItem {
        id: windowPixmap
        opacity: wrapper.coverOpacity
        width: rotation % 180 == 0 ? wrapper.width : wrapper.height
        height: rotation % 180 == 0 ? wrapper.height : wrapper.width
        windowId: wrapper.coverId?wrapper.coverId:wrapper.windowId
        radius: Theme.paddingMedium
        smooth: true
        anchors.centerIn: parent
        xScale: Math.min(1.0, (windowSize.height / windowSize.width) / (height / width))
        yScale: Math.min(1.0, (windowSize.width / windowSize.height) / (width / height))

        xOffset: rotation == 180 ? -xScale + 1 : 0
        yOffset: rotation == 90 ? -yScale + 1 : 0

        rotation: windowPixmap.windowId == wrapper.windowId && wrapper.window && wrapper.window.surface
                          ? QtQuick.Screen.angleBetween(QtQuick.Screen.primaryOrientation, wrapper.window.surface.contentOrientation)
                          : 0

        Behavior on rotation {
            SequentialAnimation {
                PauseAnimation { duration: 250 }
                PropertyAction { }
            }
        }

        Behavior on opacity {
            FadeAnimation { id: coverOpacityAnimation; duration: 500 }
        }
    }

    LauncherIcon {
        size: Theme.iconSizeMedium
        anchors.centerIn: parent
        scale: parent.width/Theme.coverSizeLarge.width
        icon: launcherItem ? launcherItem.iconId : ""
        layer.effect: null
        opacity: hideCover ? 1.0 : 0.0
        Behavior on opacity { FadeAnimation { duration: 500 } }
    }

    Loader {
        id: loader

        width: parent.width
        height: Math.min(Theme.itemSizeSmall, Math.round(windowPixmap.width / 2))
        anchors.bottom: parent.bottom
        opacity: windowPixmap.opacity

        sourceComponent: coverActionModel.count > 0 ? coverActionIndicators : undefined
    }

    Timer {
        id: startupTimer
        // For apps we know will be providing a cover window, wait up to 5sec for it to arrive,
        // otherwise you see an ugly app window -> cover window change.
        interval: coverHint && !coverId ? 5000 : 500
        onRunningChanged: {
            if (!running && _appTransitioning) {
                restart()
            }
        }
    }

    Rectangle {
        color: quickSwitchingApp ? Theme.highlightColor : Theme.highlightBackgroundColor
        anchors.fill: parent
        opacity: ((currentApp && !Lipstick.compositor.homePeeking) || quickSwitchingApp || windowMapPending || launching || wrapper.closing)
                 ? Theme.opacityLow
                 : (contentItem.pressed ? Theme.highlightBackgroundOpacity : 0)
        radius: windowPixmap.radius

        Behavior on color {
            ColorAnimation { duration: 100 }
        }

        Behavior on opacity {
            enabled: !contentItem.pressed
            NumberAnimation { duration: 50 }
        }
    }

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        scale: parent.width/Theme.coverSizeLarge.width
        color: Theme.primaryColor
        size: BusyIndicatorSize.Large
        running: launching
    }

    Component {
        id: coverActionIndicators

        Item {
            anchors.fill: parent

            Component.onCompleted: {
                var process = launcherItem ? launcherItem.fileID : "<unknown>"
                console.log("coverActionIndicators created", process)
            }
            Component.onDestruction: {
                var process = launcherItem ? launcherItem.fileID : "<unknown>"
                console.log("coverActionIndicators destroyed", process)
            }

            Rectangle {
                anchors.fill: parent
                visible: coverActionModel.background
                radius: windowPixmap.radius

                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.5; color: Theme.highlightDimmerColor }
                }
            }

            Grid {
                id: indicatorRow
                anchors.fill: parent
                columns: coverActionModel.count

                Repeater {
                    model: coverActionModel
                    delegate: MouseArea {
                        id: wrapperItem

                        objectName: "SwitcherItem_wrapperItem"

                        Component.onCompleted: {
                            var process = launcherItem ? launcherItem.fileID : "<unknown>"
                        }
                        Component.onDestruction: {
                            var process = launcherItem ? launcherItem.fileID : "<unknown>"
                        }

                        property int index: model.id
                        property url icon: model.iconSource

                        width: indicatorRow.width / coverActionModel.count
                        height: indicatorRow.height

                        enabled: !switcherRoot.housekeeping
                        propagateComposedEvents: true

                        BubbleBackground {
                            roundedCorners: {
                                if (coverActionModel.count == 1) {
                                    return BubbleBackground.BottomLeft | BubbleBackground.BottomRight
                                } else if (model.index == 0) {
                                    return BubbleBackground.BottomLeft
                                } else {
                                    return BubbleBackground.BottomRight
                                }
                            }

                            color: Theme.highlightBackgroundColor
                            anchors.fill: parent
                            visible: wrapperItem.pressed && wrapperItem.containsMouse && wrapperItem.enabled
                            opacity: Theme.highlightBackgroundOpacity
                            radius: windowPixmap.radius
                        }

                        Image {
                            id: image

                            anchors.centerIn: parent
                            width: Theme.iconSizeSmall
                            height: width
                            sourceSize.width: width
                            sourceSize.height: width
                            asynchronous: true
                            source: wrapperItem.pressed && wrapperItem.containsMouse
                                    ? iconSource + "?" + Theme.highlightColor
                                    : iconSource
                            smooth: true
                            opacity: switcherRoot.housekeeping ? 0.0 : 1.0

                            Behavior on opacity { FadeAnimation {} }
                        }

                        onClicked: coverActionModel.trigger(model.id)
                    }
                }
            }
        }
    }

    Rectangle {
        color: closeArea.pressed ? Theme.highlightColor : Theme.primaryColor
        width: Theme.iconSizeMedium
        height: width
        radius: width/2
        anchors.verticalCenter: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: closeArea.enabled ? 1.0 : 0.0

        Image {
            anchors.centerIn: parent
            source: "image://theme/icon-close-app?" + Theme.highlightBackgroundColor
        }

        Behavior on opacity { NumberAnimation { } }

        MouseArea {
            id: closeArea
            objectName: "SwitcherItem_closeArea"
            anchors {
                fill: parent
                margins: -Theme.paddingSmall        // expand a little around the button
                bottomMargin: -Theme.paddingMedium  // Bottom has a bit bigger negative margin.
            }
            enabled: !wrapper.pending && switcherRoot.housekeeping && !closeAnimation.running
            onClicked: {
                ngfEvent.play()
                wrapper.close()
            }

            NonGraphicalFeedback {
                id: ngfEvent
                event: "close_app"
            }
        }
    }

    HighlightImage {
        id: closingGraphic
        anchors.centerIn: parent
        visible: wrapper.closing
        color: Theme.lightPrimaryColor
        source: "image://theme/graphic-close-app"
        scale: wrapper.width / Theme.coverSizeLarge.width
    }

    Connections {
        target: Lipstick.compositor.appLayer
        onCloseWindow: {
            // Freeze these values to preserve the visual state of the cover
            if (wrapper.windowId == window.window.windowId) {
                wrapper.currentApp = wrapper.currentApp
                closingGraphic.visible = closingGraphic.visible
                wrapper.close()
            }
        }
        onWindowShown: {
            if (wrapper.windowId == window.window.windowId && launcherItem) {
                launcherItem.isLaunching = false
            }
        }
    }

    SequentialAnimation {
        id: closeAnimation
        ParallelAnimation {
            NumberAnimation {
                target: contentItem
                properties: "opacity"
                duration: 200
                to: 0.0
            }
            NumberAnimation {
                target: contentItem
                properties: "y"
                duration: 200
                to: contentItem.y + contentItem.height / 4
            }

            SequentialAnimation {
                PauseAnimation { duration: 170 }
                ScriptAction {
                    script: {
                        if (window) {
                            Lipstick.compositor.windowsBeingClosed = Lipstick.compositor.windowsBeingClosed.concat([window.userData])
                            if (cover && cover.surface && cover.surface.windowProperties.CATEGORY == "silica-cover") {
                                cover.surface.destroySurface()
                            } else if (window && window.surface) {
                                window.surface.destroySurface()
                            }
                        }
                        switcherModel.remove(index)
                    }
                }
            }
        }
        ScriptAction {
            script: contentItem.y = 0
        }
    }

    StartupWatcher {
        launcherItem: model.launcherItem
        running: wrapper.launching

        onStartupFailed: {
            if (wrapper.pending) {
                // Remove pending window if the process dies
                switcherModel.remove(index)
            } else {
                // Cancel loading state of retained windows.
                wrapper.launching = false
                wrapper.minimized = false
            }
        }

        onRunningChanged: {
            if (running) {
                // If there are a number of apps loading we increase the timeout
                // because we know that it will take longer to launch under load.
                timeoutAdjustment = switcherRoot.launchingCount() * 3
            }
        }
    }

    states: [
        State {
            name: "moving"
            when: wrapper.reordering
            PropertyChanges {
                target: contentItem
                scale: 1.0
                opacity: 1.0
            }
        },
        State {
            name: "closeModeEnabled"
            when: switcherRoot.housekeeping || wrapper._persistHousekeeping

            PropertyChanges {
                target: contentItem
                scale: 0.9
                opacity: 1.0
            }
        }
    ]

    transitions: [
        Transition {
            SmoothedAnimation {
                properties: "scale,opacity"
                duration: 200
                velocity: -1
            }
        }
    ]
}
