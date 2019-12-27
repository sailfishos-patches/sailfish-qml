/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Vesa Halttunen <vesa.halttunen@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import org.nemomobile.lipstick 0.1
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import org.nemomobile.configuration 1.0
import com.jolla.lipstick 0.1
import QtFeedback 5.0
import "../systemwindow"
import "../compositor"

SystemWindow {
    id: volumeBar

    property bool volumeIncreasing
    property bool lateScreenshotCapture
    property var screenshot
    property bool controllingMedia: forceMediaVolume.value ||
                                    volumeControl.mediaState === VolumeControl.MediaStateActive ||
                                    volumeControl.mediaState === VolumeControl.MediaStateForeground ||
                                    volumeControl.mediaState === VolumeControl.MediaStateBackground ||
                                    volumeControl.callActive || showContinuousVolume
    property real statusBarPushDownY: volumeArea.y + volumeArea.height
    property bool showContinuousVolume: false
    property int maximumVolume: controllingMedia ? volumeControl.maximumVolume : 100
    property real initialChange: 0
    property bool disableSmoothChange: true
    property real baseVolume
    property real continuousVolume: {
        // The maximum continuous volume that should be allowed. Plus one so that the warning is triggered.
        var max = (controllingMedia && volumeControl.restrictedVolume !== volumeControl.maximumVolume)
                    ? (volumeControl.restrictedVolume+1) : maximumVolume

        // delta ranges from -1 to 1 (ratio of window dimension plus direction)
        // Triple rate of volume change as in practice will not reach these limits.
        var d = Lipstick.compositor.volumeGestureFilterItem.delta
        return Math.min(Math.max(baseVolume + 3*d*maximumVolume, 0), max)
    }
    onContinuousVolumeChanged: {
        if (!Lipstick.compositor.volumeGestureFilterItem.active)
            return

        // Gesture only controls media volume
        if (Lipstick.compositor.volumeGestureFilterItem.deltaIncreasing) {
            if (Math.floor(continuousVolume) === 0)
                volumeControl.volume = Math.ceil(continuousVolume)
            else
                volumeControl.volume = Math.floor(continuousVolume)
        } else {
            volumeControl.volume = Math.ceil(continuousVolume)
        }
    }

    property color _foregroundColor: controllingMedia && (volumeControl.volume > volumeControl.safeVolume)
                                    ? Theme.highlightDimmerColor
                                    : Theme.primaryColor
    property color _backgroundColor: controllingMedia && (volumeControl.volume > volumeControl.safeVolume)
                                        ? Theme.primaryColor
                                        : Theme.secondaryHighlightColor

    Behavior on _foregroundColor { ColorAnimation { } }
    Behavior on _backgroundColor { ColorAnimation { } }

    // Place below other notifications
    z: -1

    onControllingMediaChanged: {
        keyRepeatDelay.stop
        keyRepeat.stop()
    }

    Component.onCompleted: {
        Lipstick.compositor.volumeWarningVisible = Qt.binding(function (){ return loader.active })
    }

    ProfileControl {
        id: profileControl

        function adjustRingtoneVolume(amount) {
            var effectiveVolume = (profile == "silent") ? 0 : ringerVolume
            var newVolume = Math.max(Math.min(effectiveVolume + amount, 100), 0)
            var newProfile = newVolume > 0 ? "general" : "silent"

            // in silent mode, avoid changing general profile level if decrease is requested
            if (profile !== "silent" || newProfile !== "silent") {
                ringerVolume = newVolume
            }

            if (newProfile != profile) {
                profile = newProfile
                if (newProfile === "silent") {
                    silenceVibra.start()
                }
            }
        }
    }

    ConfigurationValue {
        id: forceMediaVolume
        key: "/jolla/sound/force_mediavolume"
        defaultValue: false
    }

    HapticsEffect {
        id: silenceVibra
        intensity: 0.2
        duration: 85
    }

    Item {
        id: volumeArea

        width: parent.width
        height: Theme.iconSizeSmall + Theme.paddingMedium
        y: -height

        Rectangle {
            anchors.fill: parent
            color: Theme.overlayBackgroundColor
            opacity: Theme.opacityOverlay
        }

        Rectangle {
            id: volumeRect

            objectName: "volumeRect"

            // On large screens display continuous volume changes
            property real displayVolume: {
                if (!controllingMedia && profileControl.profile == "silent") {
                    return 0
                }
                if (controllingMedia && volumeControl.callActive) {
                    if (showContinuousVolume)
                        return (continuousVolume+1) / (maximumVolume+1)
                    else
                        return (volumeControl.volume+1) / (volumeControl.maximumVolume+1)
                } else {
                    if (showContinuousVolume)
                        return continuousVolume / maximumVolume
                    else if (controllingMedia)
                        return volumeControl.volume / volumeControl.maximumVolume
                    else
                        return profileControl.ringerVolume / 100
                }
            }

            property real widthFraction: displayVolume

            anchors {
                top: parent.top
                topMargin: Theme.paddingSmall/2
                bottom: parent.bottom
                bottomMargin: Theme.paddingSmall/2
                left: parent.left
            }

            width: volumeArea.width * widthFraction

            Behavior on widthFraction {
                enabled: !showContinuousVolume && !disableSmoothChange
                NumberAnimation { easing.type: Easing.OutSine }
            }

            color: _backgroundColor
        }

        Item {
            objectName: "volumeAnnotation"

            anchors.fill: parent

            property bool mute: controllingMedia
                                ? (!volumeControl.callActive && volumeControl.volume === 0)
                                : (profileControl.profile === "silent" || profileControl.ringerVolume === 0)
            property real muteOpacity: mute ? 1 : 0
            Behavior on muteOpacity {
                enabled: volumeBar.state != "" && volumeBar.state != "showBarExternal"
                FadeAnimation { property: "muteOpacity" }
            }

            Image {
                id: muteIcon

                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                opacity: parent.muteOpacity

                property string baseSource: controllingMedia ? "image://theme/icon-system-volume-mute" : "image://theme/icon-system-ringtone-mute"
                source: baseSource + "?" + _foregroundColor
            }

            Image {
                id: volumeIcon

                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                opacity: 1 - parent.muteOpacity

                property string baseSource: controllingMedia ? "image://theme/icon-system-volume" : "image://theme/icon-system-ringtone"
                source: baseSource + "?" + _foregroundColor
            }

            Label {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: muteIcon.right
                    leftMargin: Theme.paddingMedium
                }

                font.pixelSize: Theme.fontSizeExtraSmall
                opacity: parent.muteOpacity
                color: _foregroundColor

                //% "Muted"
                text: qsTrId("lipstick-jolla-home-la-muted")
            }

            Label {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: volumeIcon.right
                    leftMargin: Theme.paddingMedium
                }

                font.pixelSize: Theme.fontSizeExtraSmall
                opacity: 1 - parent.muteOpacity
                color: _foregroundColor

                text: {
                    if (controllingMedia) {
                        if (volumeControl.volume > volumeControl.safeVolume) {
                            //% "High volume"
                            return qsTrId("lipstick-jolla-home-la-high-volume")
                        } else if (volumeControl.callActive && volumeControl.volume === 0) {
                            //: Label used when minimum (unmuted) volume is set
                            //% "Minimum"
                            return qsTrId("lipstick-jolla-home-la-minimum-volume")
                        } else {
                            //% "Volume"
                            return qsTrId("lipstick-jolla-home-la-volume")
                        }
                    } else {
                        //% "Ringtone volume"
                        return qsTrId("lipstick-jolla-home-la-ringtone_volume")
                    }
                }
            }
        }
    }

    states: [
        State {
            name: "showBar"
            PropertyChanges {
                target: volumeArea
                y: 0
            }
        },
        State {
            name: "showBarKey"
            extend: "showBar"
            PropertyChanges {
                target: volumeBar
                disableSmoothChange: false
            }
            PropertyChanges {
                target: volumeRect
                widthFraction: volumeRect.displayVolume
            }
        },
        State {
            name: "showBarGesture"
            extend: "showBar"
            PropertyChanges {
                target: volumeBar
                showContinuousVolume: Screen.sizeCategory >= Screen.Large
            }
        },
        State {
            name: "showBarExternal"
            extend: "showBar"
            PropertyChanges {
                target: volumeBar
                controllingMedia: false
                showContinuousVolume: false
            }
        }
    ]

    transitions: [
        Transition {
            from: ""
            to: "showBarKey"
            SequentialAnimation {
                ScriptAction {
                    script: {
                        volumeRect.widthFraction = volumeRect.displayVolume + initialChange
                    }
                }
                NumberAnimation {
                    target: volumeArea
                    property: "y"
                    duration: 200
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: volumeRect
                    property: "widthFraction"
                    easing.type: Easing.OutSine
                }
                PropertyAction {
                    target: volumeBar
                    property: "disableSmoothChange"
                }
                ScriptAction { script: hideTimer.restart() }
            }
        },
        Transition {
            from: ""
            to: "showBarGesture"
            SequentialAnimation {
                PropertyAction {
                    target: volumeBar
                    property: "showContinuousVolume"
                }
                NumberAnimation {
                    target: volumeArea
                    property: "y"
                    duration: 200
                    easing.type: Easing.OutQuad
                }
                ScriptAction { script: hideTimer.restart() }
            }
        },
        Transition {
            from: ""
            to: "showBarExternal"
            SequentialAnimation {
                PauseAnimation {
                    duration: 150
                }
                NumberAnimation {
                    target: volumeArea
                    property: "y"
                    duration: 300
                    easing.type: Easing.InOutQuad
                }
                ScriptAction { script: hideTimer.restart() }
            }
        },
        Transition {
            to: ""
            SequentialAnimation {
                NumberAnimation {
                    target: volumeArea
                    property: "y"
                    duration: 200
                    easing.type: Easing.OutQuad
                }
                PropertyAction {
                    target: volumeBar
                    properties: "disableSmoothChange, showContinuousVolume"
                }
                PropertyAction {
                    target: volumeRect
                    property: "widthFraction"
                }
                ScriptAction {
                    script: {
                        volumeControl.windowVisible = false
                        loader.warningActive = false
                        if (lateScreenshotCapture) {
                            if (!screenshot) {
                                var component = Qt.createComponent(Qt.resolvedUrl("Screenshot.qml"))
                                if (component.status == Component.Ready) {
                                    screenshot = component.createObject(volumeBar)
                                } else {
                                    console.warn("Screenshot object instantiation failed:", component.errorString())
                                }
                            }
                            if (screenshot) {
                                screenshot.capture()
                            }
                        }
                        lateScreenshotCapture = false
                    }
                }
            }
        }
    ]

    Loader {
        id: loader

        property bool warningActive

        function showWarning(initial) {
            warningActive = true
            loader.item.initial = initial
            loader.item.dismiss.connect(function () {
                opacity = 0.0
                warningActive = false
                hideTimer.restart()
            })
            hideTimer.stop()
            opacity = 1.0
        }

        source: "WarningNote.qml"
        active: warningActive || warningFade.running
        opacity: 0.0

        anchors {
            top: volumeArea.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        Behavior on opacity { FadeAnimator { id: warningFade; duration: 300  } }
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: {
            if (!Lipstick.compositor.volumeGestureFilterItem.active)
                volumeBar.state = ""
        }
    }

    Timer {
        id: keyRepeatDelay
        interval: 600
        onTriggered: keyRepeat.start()
    }

    Timer {
        id: keyRepeat
        interval: volumeBar.controllingMedia ? 75 : 300
        repeat: true
        onTriggered: {
            if (volumeBar.controllingMedia) {
                volumeControl.volume = volumeControl.volume + (volumeBar.volumeIncreasing ? 1 : -1)
            } else {
                profileControl.adjustRingtoneVolume(volumeBar.volumeIncreasing ? 20 : -20)
            }

            restartHideTimerIfWindowVisibleAndWarningNotVisible()
        }
    }

    Connections {
        target: volumeControl
        onWindowVisibleChanged: {
            if (volumeControl.windowVisible) {
                if (volumeBar.state == "") {
                    if (Lipstick.compositor.volumeGestureFilterItem.active) {
                        volumeBar.state = "showBarGesture"
                    } else {
                        volumeBar.state = "showBarKey"
                        hideTimer.restart()
                    }
                }
            }
        }
        onVolumeChanged: restartHideTimerIfWindowVisibleAndWarningNotVisible()
        onVolumeKeyPressed: {
            if (keyRepeat.running || keyRepeatDelay.running) {
                if (Lipstick.compositor.visible) {
                    screenshotTimer.restart()
                }
                return
            }

            volumeBar.volumeIncreasing = (key == Qt.Key_VolumeUp)

            if (volumeBar.controllingMedia) {
                if (volumeIncreasing)
                    initialChange = volumeControl.volume === volumeControl.maximumVolume ? 0 : -1 / (volumeControl.maximumVolume+1)
                else
                    initialChange = volumeControl.volume === 0 ? 0 : 1 / (volumeControl.maximumVolume+1)

                keyRepeat.stop()
                keyRepeatDelay.restart()
                volumeControl.volume = volumeControl.volume + (volumeBar.volumeIncreasing ? 1 : -1)
            } else {
                if (volumeControl.windowVisible) {
                    if (volumeIncreasing)
                        initialChange = profileControl.ringerVolume === 100 ? 0 : -0.2
                    else
                        initialChange = profileControl.ringerVolume === 0 ? 0 : 0.2

                    profileControl.adjustRingtoneVolume(volumeBar.volumeIncreasing ? 20 : -20)
                } else {
                    initialChange = 0
                }

                keyRepeat.restart() // no initial delay
            }

            volumeBar.state = "showBarKey"
            volumeControl.windowVisible = true
            restartHideTimerIfWindowVisibleAndWarningNotVisible()
        }
        onVolumeKeyReleased: {
            initialChange = 0
            if (volumeBar.controllingMedia)
                baseVolume = volumeControl.volume
            if (volumeBar.volumeIncreasing == (key == Qt.Key_VolumeUp)) {
                // Handle pressing both buttons and releasing the first, though
                // in that case keyRepeat is probably already stopped by screenshotTimer
                keyRepeat.stop()
                keyRepeatDelay.stop()
            }
            screenshotTimer.stop()
            lateScreenshotCapture = false
        }
        onShowAudioWarning: loader.showWarning(initial)
    }

    Connections {
        target: Lipstick.compositor.volumeGestureFilterItem
        onActiveChanged: {
            if (Lipstick.compositor.volumeGestureFilterItem.active) {
                if (!volumeControl.windowVisible)
                    baseVolume = continuousVolume
                volumeBar.state = "showBarGesture"
                volumeControl.windowVisible = true
                hideTimer.stop()
            } else {
                baseVolume = continuousVolume
                restartHideTimerIfWindowVisibleAndWarningNotVisible()
            }
        }
    }

    Connections {
        target: Desktop
        onShowVolumeBar: {
            volumeBar.state = "showBarExternal"
            volumeControl.windowVisible = true
            restartHideTimerIfWindowVisibleAndWarningNotVisible()
        }
    }

    Timer {
        id: screenshotTimer
        interval: 200
        onTriggered: {
            lateScreenshotCapture = true
            keyRepeat.stop()
            keyRepeatDelay.stop()
            initialChange = 0
            if (volumeBar.controllingMedia)
                baseVolume = volumeControl.volume
            volumeBar.volumeIncreasing = false
            volumeBar.state = ""
        }
    }

    function restartHideTimerIfWindowVisibleAndWarningNotVisible() {
        if (volumeControl.windowVisible && !loader.warningActive && !Lipstick.compositor.volumeGestureFilterItem.active) {
            hideTimer.restart()
        }
    }
}
