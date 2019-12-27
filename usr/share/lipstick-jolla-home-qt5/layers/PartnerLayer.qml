import QtQuick 2.2
import QtQuick.Window 2.1 as QtQuick
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1
import com.jolla.lipstick 0.1
import Sailfish.Lipstick 1.0
import "../compositor"
import "../switcher"

PannableLayer {
    id: partnerItem

    property alias contentItem: partnerParent
    property alias overlayItem: overlay

    property QtObject launcherItem

    property bool available: window != null
    property bool moving
    property bool panning
    property bool peeking
    property bool pending
    property alias launching: startupWatcher.running

    property real peekProgress

    property bool isActiveInHome
    property bool launcherActive

    property real minimizedScale
    property real minimizeThreshold
    property bool _exceedingMinimizeThreshold: maximized && peekProgress == 1.0
    property bool _minimizeThresholdExceeded
    property bool _waitingForLauncher

    property bool _showWindow
    readonly property bool _showSplash: (partnerItem.pending || !windowPixmap.hasPixmap)
                && (!partnerParent.window || windowFadeIn.running)
    property bool _cacheInvalidated

    function start() {
        if (launcherItem && !launcherItem.isLaunching) {
            if (launcherActive) {
                launching = true
                launcherItem.launchApplication()
                _waitingForLauncher = false
            } else {
                _waitingForLauncher = true
            }
        }
    }

    function _startFadeIn() {
        if (visible) {
            partnerParent.opacity = 0
            windowFadeIn.start()
        } else {
            windowFadeIn.stop()
            partnerParent.opacity = 1
            pending = false
        }
    }

    window: partnerParent
    maximized: false
    minimizeMargin: partnerSpace.offset

    statusOpacity: 1.0 - Math.min(1.0, (partnerSpace.scale - minimizedScale)/(1.0-minimizedScale)*2)

    onMovingChanged: {
        showDelay.running = !moving && isCurrentItem
        if (!moving && !isCurrentItem) {
            _showWindow = false
        }
    }

    onPeekingChanged: {
        if (!peeking && _minimizeThresholdExceeded) {
            maximized = false
            _minimizeThresholdExceeded = false
        }
    }

    on_ExceedingMinimizeThresholdChanged: {
        if (_exceedingMinimizeThreshold) {
            _minimizeThresholdExceeded = true
        }
    }

    onIsActiveInHomeChanged: {
        if (!isActiveInHome) {
            showDelay.running = false
            _waitingForLauncher = false
            if (!moving) {
                _showWindow = false
            }
            maximized = false
        }
    }

    onMaximizedChanged: {
        if (maximized && partnerParent.window) {
            partnerParent.window.forceActiveFocus()
        } else if (!maximized && Lipstick.compositor.deviceIsLocked) {
            lipstickSettings.lockScreen(true)
        }
    }

    onLauncherActiveChanged: {
        if (launcherActive && _waitingForLauncher) {
            start()
        }
    }

    Timer {
        id: showDelay

        interval: 500
        onTriggered: {
            partnerItem._showWindow = true
            if (partnerItem.pending && !partnerItem.launching) {
                partnerItem.start()
            }
            if (partnerParent.mapped) {
                partnerItem._cacheInvalidated = true
            }
        }
    }

    StartupWatcher {
        id: startupWatcher

        launcherItem: partnerItem.launcherItem
        onStartupFailed: {
            running = false
        }
    }

    MouseArea {
        id: partnerSpace

        property real offset

        objectName: "PartnerSpace"
        width: Lipstick.compositor.width
        height: Lipstick.compositor.height

        anchors {
            centerIn: partnerItem
            horizontalCenterOffset: offset
        }

        scale: partnerItem.minimizedScale
        enabled: !partnerItem.maximized
        onClicked: {
            partnerItem.maximized = true
            if (!partnerParent.window) {
                partnerItem.start()
            }
        }

        states: [
            State {
                name: "panning"
                when: partnerItem.maximized
                            && (partnerItem.panning || partnerItem.peeking)
                            && !partnerItem._minimizeThresholdExceeded
                PropertyChanges {
                    target: partnerSpace
                    scale: partnerItem.minimizedScale
                                + ((1.0 - partnerItem.minimizedScale)
                                    * (1.0 - partnerItem.peekProgress))
                    offset: Math.max(
                                -partnerItem.minimizeThreshold,
                                Math.min(partnerItem.minimizeThreshold, -partnerItem.offset))
                }
                PropertyChanges {
                    target: partnerItem
                    restoreEntryValues: false
                    opaque: false
                }
            }, State {
                name: "maximized"
                when: partnerItem.maximized && !partnerItem._minimizeThresholdExceeded
                PropertyChanges {
                    target: partnerSpace
                    scale: 1.0
                }
            }, State {
                name: "willMinimize"
                when: partnerItem.maximized && partnerItem._minimizeThresholdExceeded
                PropertyChanges {
                    target: partnerSpace
                    scale: partnerItem.minimizedScale
                    offset: Math.max(
                                -partnerItem.minimizeThreshold,
                                Math.min(partnerItem.minimizeThreshold, -partnerItem.offset))
                }
                PropertyChanges {
                    target: partnerItem
                    restoreEntryValues: false
                    opaque: false
                }
            }, State {
                name: "minimized"
                when: !partnerItem.maximized
                PropertyChanges {
                    target: partnerSpace
                    scale: partnerItem.minimizedScale
                }
                PropertyChanges {
                    target: partnerItem
                    restoreEntryValues: false
                    opaque: false
                }
            }
        ]

        transitions: [
            Transition {
                to: "maximized"

                SequentialAnimation {
                    NumberAnimation {
                        properties: "scale,offset"
                        duration: 300
                        easing.type: Easing.InOutQuad
                    }
                    ScriptAction {
                        script: partnerItem.opaque = Qt.binding(function() {
                            return partnerParent.window != null
                        })
                    }
                }
            }, Transition {
                to: "minimized"
                from: "maximized"

                NumberAnimation {
                    properties: "scale,offset"
                    duration: 300
                    easing.type: Easing.InOutQuad
                }
            }, Transition {
                to: "minimized"

                NumberAnimation {
                    properties: "offset"
                    duration: 300
                    easing.type: Easing.InOutQuad
                }
            }
        ]

        Item {
            id: cacheSource

            anchors.fill: parent
            visible: snapshot.visible

            WindowPixmapItem {
                id: windowPixmap

                anchors.fill: parent
                opaque: true

                objectName: partnerItem.objectName
                rotation: partnerParent.orientation & (Qt.InvertedPortraitOrientation | Qt.InvertedLandscapeOrientation)
                          ? 180
                          : 0
            }
        }


        WindowCache {
            id: windowCache

            source: windowPixmap.hasPixmap ? cacheSource : null
            applicationId: partnerItem.launcherItem ? partnerItem.launcherItem.fileID : ""
            orientation: partnerParent.orientation
        }

        Component {
            id: splash

            Image {
                anchors.fill: parent
                asynchronous: true
                source: windowCache.location

                fillMode: Image.PreserveAspectCrop
                rotation: windowPixmap.rotation
            }
        }

        Component {
            id: fallbackSplash
            Item {
                anchors.fill: parent

                GlassBackground {
                    anchors.fill: parent
                    radius: Theme.paddingSmall
                    scale: partnerSpace.scale
                }

                LauncherIcon {
                    id: launcherIcon

                    size: Theme.iconSizeMedium
                    anchors.centerIn: parent
                    icon: partnerItem.launcherItem ? partnerItem.launcherItem.iconId : ""
                    layer.effect: null
                }
            }
        }

        Loader {
            anchors.fill: parent
            visible: partnerItem._showSplash
            sourceComponent: {
                if (!partnerItem._showSplash) {
                    return null
                } else if (windowCache.location != "") {
                    return splash
                } else {
                    return fallbackSplash
                }
            }
        }

        ShaderEffectSource {
            id: snapshot

            anchors.fill: parent
            visible: !partnerItem.pending && (!partnerParent.mapped || windowFadeIn.running)
            hideSource: true
            live: false

            onVisibleChanged: {
                if (visible) {
                    sourceItem = windowPixmap
                    scheduleUpdate()
                }
            }
        }

        Item {
            id: partnerParent

            property Item window
            property bool mapped
            readonly property int windowType: WindowType.PartnerSpace
            readonly property int orientation: partnerItem.maximized
                        && window
                        && window.surface
                    ? (window.surface.contentOrientation != Qt.PrimaryOrientation
                        ? window.surface.contentOrientation
                        : QtQuick.Screen.primaryOrientation)
                    : Lipstick.compositor.homeOrientation
            readonly property alias layerItem: partnerItem
            property real windowOpacity: 1.0
            property rect backgroundRect: Qt.rect(0, 0, width, height)

            onWindowChanged: {
                if (window) {
                    windowPixmap.windowId = window.windowId
                    partnerItem._cacheInvalidated = true
                    partnerItem._startFadeIn()
                    mapped = true
                    startupWatcher.running = false
                    window.surface.visibility = QtQuick.Window.FullScreen
                    window.surface.visibility = Qt.binding(function() {
                        if (!partnerItem.isActiveInHome && !partnerItem.visible) {
                            return QtQuick.Window.Hidden
                        } else if (partnerItem.opaque) {
                            return QtQuick.Window.FullScreen
                        } else if (partnerItem._showWindow) {
                            return QtQuick.Window.Windowed
                        } else {
                            return QtQuick.Window.Hidden
                        }
                    })
                } else {
                    mapped = false
                    partnerItem.maximized = false
                }
            }

            anchors.fill: partnerSpace
            enabled: partnerItem.opaque
            opacity: 0
            visible: mapped

            FadeAnimation {
                id: windowFadeIn

                target: partnerParent
                duration: 400
                from: 0
                to: 1.0
                onStopped: {
                    partnerItem.pending = false
                    snapshot.sourceItem = null
                    snapshot.scheduleUpdate()
                }
            }

            Connections {
                target: partnerParent.window && partnerParent.window.surface
                onMapped: {
                    partnerItem._startFadeIn()
                    partnerItem._cacheInvalidated = true
                    partnerParent.mapped = true
                }
                onUnmapped: {
                    partnerParent.mapped = false
                }

                onVisibilityChanged: {
                    switch (partnerParent.window.surface.visibility) {
                    case QtQuick.Window.FullScreen:
                        if (partnerParent.mapped) {
                            partnerItem._cacheInvalidated = true
                        }
                        break
                    case QtQuick.Window.Hidden:
                        if (partnerItem._cacheInvalidated) {
                            partnerItem._cacheInvalidated = false
                            windowCache.updateCache()
                        }
                        break
                    }
                }
            }
        }

        Item {
            id: overlay
            anchors.fill: partnerSpace
            enabled: partnerParent.enabled
        }
    }

    BusyIndicator {
        anchors.centerIn: partnerSpace
        color: Theme.primaryColor
        size: BusyIndicatorSize.Large
        running: startupWatcher.running || partnerItem._waitingForLauncher
    }
}
