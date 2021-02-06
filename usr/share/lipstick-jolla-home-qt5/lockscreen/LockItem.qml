/****************************************************************************
**
** Copyright (c) 2015 - 2019 Jolla Ltd.
** Copyright (c) 2019 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************/

import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Telephony 1.0
import Sailfish.Media 1.0
import Nemo.DBus 2.0
import com.jolla.lipstick 0.1
import com.jolla.settings.system 1.0
import org.nemomobile.lipstick 0.1
import "../backgrounds"
import "../main"
import "../statusarea"

SilicaFlickable {
    id: lockItem
    readonly property alias indicatorSize: rightIndicator.width
    property bool allowAnimations
    property alias clock: clock
    property alias mpris: mpris
    property alias leftIndicator: leftIndicator
    property alias rightIndicator: rightIndicator
    property string iconSuffix
    property real contentTopMargin
    property int statusBarHeight

    readonly property real verticalOffset: contentTopMargin / 2

    function reset() {
        // Hide lock items and reset states.
        if (!Lipstick.compositor.notificationOverviewLayer.hasNotifications) {
            leftIndicator.reset()
        }
        rightIndicator.reset()
    }

    function hintEdges() {
        if (!lockScreen.lowPowerMode && lipstickSettings.blankingPolicy == "default") {
            if (!Lipstick.compositor.notificationOverviewLayer.hasNotifications) {
                leftIndicator.hinting = true
            }
            rightIndicator.hinting = true
        }
    }

    contentWidth: width
    contentHeight: height

    Shortcuts {
        id: shortcuts
    }

    onVisibleChanged: {
        if (!visible) {
            mce.endBlankDelay()
        }
    }

    Connections {
        target: Lipstick.compositor
        // Animate closing, otherwise you catch a glimpse of the view jumping before te screen is off.
        onDisplayOff: pullDownMenu.close(false)
    }

    PullDownMenu {
        id: pullDownMenu

        property var menuAction

        enabled: shortcutRepeater.count && !lipstickSettings.lowPowerMode && Lipstick.compositor.systemInitComplete && lockScreen.locked
        opacity: enabled ? 1 : 0
        Behavior on opacity { FadeAnimation {} }

        Repeater {
            id: shortcutRepeater

            model: shortcuts.lockscreenShortcuts

            MenuItem {
                property bool isApp: shortcuts.isDesktopFile(modelData)
                property LauncherItem launcherItem: isApp ? shortcuts.itemForFilePath(modelData) : null

                visible: text != ''
                text: {
                    return launcherItem && launcherItem.isValid ? launcherItem.title : ''
                }
                onClicked: pullDownMenu.menuAction = launcherItem
            }
        }

        onActiveChanged: {
            if (active) {
                lipstickSettings.lockscreenVisible = true
            } else if (menuAction) {
                lockItem.reset()
                if ('exec' in menuAction) {
                    Desktop.instance.switcher.activateWindowFor(menuAction, true, true)
                }
                menuAction = undefined
            }
        }
    }

    MouseArea {
        objectName: "LockItem_hintEdges"
        anchors.fill: parent
        enabled: !lockScreen.lowPowerMode && lockScreen.locked && !lockScreen.panning
        onClicked: hintEdges()
    }

    ContrastBackground {
        id: centerBackground

        x: (lockItem.width - width) / 2
        y: lockItem.contentTopMargin - clock.offset + (clock.cannotCenter
                ? Theme.paddingLarge
                : (lockItem.height - lockItem.contentTopMargin - height) / 2)

        width: Math.max(clock.width, weatherIndicator.width)
        height: clock.height + weatherIndicator.height

        opacity: Math.min(clock.transitionOpacity, clock.unlockOpacity)

        Clock {
            id: clock

            property bool cannotCenter: Screen.sizeCategory <= Screen.Medium && lockScreenPage.isPortrait

            property real peekOffset: clock.followPeekPosition
                    ? lockScreen.progress * (lockItem.contentTopMargin - lockItem.statusBarHeight)
                    : 0
            property real animationOffset
            readonly property real offset: Math.max(peekOffset, animationOffset)
            property real transitionOpacity: 1.0

            property real pannableProgress: Math.min(1.0, Math.abs(lockContainer.offset) / lockScreen.peekFilter.threshold)
            property real unlockOpacity: lockScreen.locked ? 1 - (deviceLockItem.locked ? pannableProgress : lockScreen.progress) : 0.0

            property string positionState: {
                if (lockScreen.lowPowerMode) {
                    return "fixed-center"
                } else if (Lipstick.compositor.lockScreenLayer.closing) {
                    return "raised"
                } else if (!lockScreen.locked && !visible && !Lipstick.compositor.cameraLayer.exposed) {
                    return "fixed-raised"
                } else if (!lockItem.allowAnimations) {
                    return lockScreen.lockScreenAnimated ? "raised" : "fixed-center"
                } else if (lockScreen.panning) {
                    return "panning"
                } else if ((!lockScreen.locked && !Lipstick.compositor.cameraLayer.exposed)
                           || Lipstick.compositor.notificationOverviewLayer.revealingEventsView) {
                    return "raised"
                } else {
                    return "center"
                }
            }

            onPositionStateChanged: {
                if (positionState == "fixed-raised") {
                    offsetAnimation.stop()
                    animationOffset = lockScreen.peekFilter.threshold * 0.5
                    opacityAnimation.stop()
                    transitionOpacity = 0
                } else if (positionState == "fixed-center") {
                    offsetAnimation.stop()
                    animationOffset = 0
                    opacityAnimation.stop()
                    transitionOpacity = 1
                } else if (positionState == "raised") {
                    offsetAnimation.from = offset
                    offsetAnimation.to = lockScreen.peekFilter.threshold * 0.5
                    offsetAnimation.duration = 400
                    offsetAnimation.restart()
                    opacityAnimation.duration = 400
                    opacityAnimation.to = 0
                    opacityAnimation.restart()
                } else {
                    offsetAnimation.from = offset
                    offsetAnimation.to = 0
                    offsetAnimation.duration = 500
                    offsetAnimation.restart()
                    opacityAnimation.duration = 500
                    opacityAnimation.to = 1
                    opacityAnimation.restart()
                }
            }

            FadeAnimation {
                id: opacityAnimation
                target: clock
                property: "transitionOpacity"
            }

            NumberAnimation on animationOffset {
                id: offsetAnimation
                running: false
                easing.type: Easing.InOutQuad
            }

            anchors.horizontalCenter: parent.horizontalCenter

            color: lockScreen.textColor
            updatesEnabled: visible
        }

        WeatherIndicatorLoader {
            id: weatherIndicator

            anchors {
                top: clock.bottom
                horizontalCenter: clock.horizontalCenter
            }
            temperatureFontPixelSize: clock.weekdayFont.pixelSize
            active: visible
        }
    }

    ContrastBackground {
        id: mprisBackground

        visible: mpris.item && mpris.item.enabled

        x: (lockItem.width - width) / 2
        y: bottomBackground.y - height - Theme.paddingMedium

        width: Screen.sizeCategory > Screen.Medium ? 4 * Theme.itemSizeExtraLarge : 0.75 * lockItem.width
        height: mpris.item ? mpris.item.height : 0

        opacity: centerBackground.opacity

        MprisPlayerControls {
            id: mpris

            onItemChanged: {
                if (item) {
                    item.textColor = Qt.binding(function() { return lockScreen.textColor })
                    item.width = Qt.binding(function() { return mprisBackground.width })

                    item.buttonSize = Screen.sizeCategory > Screen.Medium ? Theme.iconSizeExtraLarge : Theme.iconSizeLarge

                    item.playPauseRequested.connect(mce.startBlankDelay)
                    item.nextRequested.connect(mce.startBlankDelay)
                    item.previousRequested.connect(mce.startBlankDelay)
                }
            }

            Timer {
                id: mprisExpiryTimer

                readonly property bool playing: mpris.item && mpris.item.isPlaying

                interval: 30 * 60 * 1000

                onPlayingChanged: {
                    if (playing) {
                        stop()
                        mpris.item.enabled = true
                    } else {
                        restart()
                    }
                }

                onTriggered: mpris.item.enabled = false
            }
        }

        DBusInterface {
            id: mce

            bus: DBus.SystemBus
            service: "com.nokia.mce"
            path: "/com/nokia/mce/request"
            iface: "com.nokia.mce.request"

            function startBlankDelay() {
                mce.call("notification_begin_req", ["mpris_lock_blank_delay", 3000, 2000])
            }

            function endBlankDelay() {
                mce.call("notification_end_req", ["mpris_lock_blank_delay", 0])
            }
        }
    }

    ContrastBackground {
        id: bottomBackground

        y: lockItem.height - height - Theme.paddingSmall
        width: lockItem.width
        height: bottomControls.height

        visible: clock.visible
        opacity: clock.transitionOpacity

        Column {
            id: bottomControls

            spacing: Theme.paddingSmall

            width: bottomBackground.width

            OngoingCall {
            }

            Row {
                id: cellInfoContainer

                anchors.horizontalCenter: parent.horizontalCenter
                opacity: lipstickSettings.lowPowerMode ? 0.0 : 1.0

                // Pressable coloring doesn't make sense here rather active modem should get emphasized (more prominent)
                // => higher contrast should indicate the selected sim.
                // => on always ask mode, keep sim indicator in highlight color
                function color(modemPath) {
                    return (!Telephony.promptForVoiceSim && Desktop.simManager.activeModem === modemPath)
                            ? lockScreen.textColor
                            : Theme.highlightColor
                }

                CellularNetworkNameStatusIndicator {
                    id: cellName1
                    modemPath: Desktop.simManager.enabledModems[0] || ""
                    maxWidth: Desktop.showDualSim
                              ? lockItem.width/2 - Theme.horizontalPageMargin - Theme.paddingMedium
                              : lockItem.width - 2*Theme.horizontalPageMargin
                    color: cellInfoContainer.color(modemPath)
                }
                Label {
                    id: separator
                    text: " | "
                    visible: Desktop.showDualSim && cellName1.visible && cellName2.visible
                    color: Telephony.promptForVoiceSim ? Theme.highlightColor : Theme.primaryColor
                }
                Loader {
                    id: cellName2
                    active: Desktop.showDualSim
                    visible: item && item.textVisible
                    sourceComponent: CellularNetworkNameStatusIndicator {
                        modemPath: Desktop.simManager.enabledModems[1] || ""
                        maxWidth: lockItem.width/2 - Theme.horizontalPageMargin - Theme.paddingMedium
                        color: cellInfoContainer.color(modemPath)
                    }
                }
            }

            Image {
                property real cameraOpacity: Lipstick.compositor.cameraLayer.canActivate ? 1.0 : 0.0
                source: "image://theme/icon-camera-camera-mode?" + Theme.lightPrimaryColor
                opacity: lipstickSettings.lowPowerMode ? 0.0 : cameraOpacity
                Behavior on cameraOpacity { FadeAnimation {} }
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    EdgeIndicator {
        id: leftIndicator

        objectName: "leftIndicator"

        y: lockItem.contentTopMargin
           + ((lockItem.height - lockItem.contentTopMargin - height) / 2)
           - lockItem.verticalOffset

        active: lockItem.allowAnimations
        rotation: 90
        peeking: lockScreen.panning && lockScreen.absoluteProgress > 0 && lockContainer.isCurrentItem
        peekProgress: lockScreen.progress * lockScreen.peekFilter.threshold
        locked: lockScreen.locked && !Lipstick.compositor.notificationOverviewLayer.animating
        fadeoutWhenHiding: lockContainer.leftItem || lockContainer.rightItem

        onPeekingChanged: {
            if (peeking) {
                rightIndicator.hinting = false
            }
        }
    }

    EdgeIndicator {
        id: rightIndicator

        objectName: "rightIndicator"

        x: lockItem.width - width
        y: leftIndicator.y

        active: lockItem.allowAnimations && !Lipstick.compositor.notificationsAnimating
        rotation: -90
        peeking: lockScreen.panning && lockScreen.absoluteProgress < 0 && lockContainer.isCurrentItem
        peekProgress: lockScreen.progress * lockScreen.peekFilter.threshold
        locked: lockScreen.locked
        fadeoutWhenHiding: lockContainer.leftItem || lockContainer.rightItem

        onPeekingChanged: {
            if (peeking) {
                leftIndicator.hinting = false
            }
        }
    }
}
