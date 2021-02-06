/*
 * Copyright (c) 2012 - 2020 Jolla Ltd.
 * Copyright (c) 2019 - 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0

SilicaItem {
    id: incomingCallControl

    readonly property bool animationRunning: resetAcceptAnimation.running || resetHangupAnimation.running
                                             || commitHangupAnimation.running || commitAcceptAnimation.running
    readonly property int arrowAnimationDuration: 600
    readonly property int arrowAnimationDistance: Theme.itemSizeMedium
    readonly property int handleRotationAmplitude: 8
    readonly property int handleRotationDuration: 100
    readonly property int resetAnimationDuration: 400
    property alias answerHighlightColor: acceptIndicatorLeftArrow.color
    property alias rejectHighlightColor: hangupIndicator.color
    property int swipeAmount
    property int maxHorizontalTranslate: parent.width * 0.4
    readonly property int maxVerticalTranslate: silencedOptions.height + silencedOptions.anchors.bottomMargin
    readonly property real verticalSpeed: isPortrait ? 1.0 : 0.5
    property bool playHints
    property bool answering
    property bool hangingUp
    property bool directionLeft
    property real progress
    readonly property bool allowHangup: main.state === "incoming"
    readonly property int controlsYOffset: allowHangup ? 0 : -maxVerticalTranslate * verticalSpeed

    onAllowHangupChanged: {
        if (allowHangup) {
            _stopTimers()
            silencedOptions.y = Screen.height
            verticalGestureTranslate.y = 0
        } else {
            commitRejectGesture()
        }
    }

    Connections {
        target: callingView
        onIsPortraitChanged: {
            verticalGestureTranslate.y = incomingCallControl.controlsYOffset
        }
    }

    width: parent.width
    height: parent.height

    function _progressColor(desired) {
        var r, g, b

        if (palette.colorScheme === Theme.LightOnDark) {
            r = 1.0 - (1.0 - desired.r) * progress
            g = 1.0 - (1.0 - desired.g) * progress
            b = 1.0 - (1.0 - desired.b) * progress
        } else {
            r = desired.r * progress
            g = desired.g * progress
            b = desired.b * progress
        }

        return Qt.rgba(r, g, b, desired.a)
    }

    function _stopAnimations() {
        resetAcceptAnimation.stop()
        resetHangupAnimation.stop()
        commitHangupAnimation.stop()
        commitAcceptAnimation.stop()
    }

    function _stopTimers() {
        hangupHintPressTimer.stop()
        hangupHintTimer.stop()
        acceptHintPressTimer.stop()
        acceptHintTimer.stop()
    }

    function startAcceptGesture() {
        reset()

        acceptIndicatorRectangle.x = Qt.binding((function() {
            return incomingCallControl.directionLeft
                   ? (incomingCallControl.width + incomingCallControl.swipeAmount)
                   : (-incomingCallControl.width + incomingCallControl.swipeAmount)
        }))
        acceptIndicatorRectangle.opacity = Qt.binding(function() { return incomingCallControl.progress * Theme.opacityHigh })
        acceptIndicator.anchors.horizontalCenterOffset = Qt.binding(function() {
            var threshold = incomingCallControl.width * 0.25
            var disance = Math.abs(incomingCallControl.swipeAmount)

            // Before the threshold, follow user's finger exactly
            if (disance <= threshold) {
                return incomingCallControl.swipeAmount
            }

            // After the threshold, show it down so that the phone handle icon stays on the screen
            var diff = disance - threshold
            var sign = incomingCallControl.swipeAmount < 0 ? -1.0 : 1.0
            return Math.floor(threshold + (diff * 0.5)) * sign
        })
        phoneHandleIcon.rotation = Qt.binding(function() { return -incomingCallControl.progress * 45 })
        phoneHandleIcon.color = Qt.binding(function() { return _progressColor(answerHighlightColor) })
    }

    function stopAcceptGesture() {
        _stopAnimations()
        acceptIndicatorRectangle.x = acceptIndicatorRectangle.x // Remove binding
        acceptIndicatorRectangle.opacity = acceptIndicatorRectangle.opacity // Remove binding
        acceptIndicator.anchors.horizontalCenterOffset = acceptIndicator.anchors.horizontalCenterOffset // Remove binding
        phoneHandleIcon.rotation = phoneHandleIcon.rotation // Remove binding
        phoneHandleIcon.color = phoneHandleIcon.color // Remove binding
        resetAcceptAnimation.start()
    }

    function commitAcceptGesture() {
        _stopAnimations()
        acceptIndicatorRectangle.x = acceptIndicatorRectangle.x // Remove binding
        acceptIndicatorRectangle.opacity = acceptIndicatorRectangle.opacity // Remove binding
        acceptIndicator.anchors.horizontalCenterOffset = acceptIndicator.anchors.horizontalCenterOffset // Remove binding
        phoneHandleIcon.rotation = phoneHandleIcon.rotation // Remove binding
        phoneHandleIcon.color = phoneHandleIcon.color // Remove binding
        commitAcceptAnimation.start()
    }

    function startRejectGesture() {
        reset()
        verticalGestureTranslate.y = Qt.binding(function() {
            return incomingCallControl.controlsYOffset + Math.min(0, Math.max(-incomingCallControl.maxVerticalTranslate, incomingCallControl.swipeAmount) * verticalSpeed)
        })
        phoneHandleIcon.rotation = Qt.binding(function() { return incomingCallControl.progress * 30 })
        silencedOptions.y = Qt.binding(function() {
            return Math.max(incomingCallControl.height + incomingCallControl.swipeAmount, incomingCallControl.height - incomingCallControl.maxVerticalTranslate)
        })
    }

    function stopRejectGesture() {
        _stopAnimations()
        verticalGestureTranslate.y = verticalGestureTranslate.y // Remove binding
        phoneHandleIcon.rotation = phoneHandleIcon.rotation // Remove binding
        phoneHandleIcon.color = phoneHandleIcon.color // Remove binding
        silencedOptions.y = silencedOptions.y // Remove binding
        resetHangupAnimation.start()
    }

    function commitRejectGesture() {
        _stopAnimations()
        verticalGestureTranslate.y = verticalGestureTranslate.y // Remove binding
        phoneHandleIcon.rotation = phoneHandleIcon.rotation // Remove binding
        phoneHandleIcon.color = phoneHandleIcon.color // Remove binding
        silencedOptions.y = silencedOptions.y // Remove binding
        commitHangupAnimation.start()
    }

    function reset() {
        _stopAnimations()
        _stopTimers()
        acceptIndicatorRectangle.x = incomingCallControl.width
        acceptIndicatorRectangle.opacity = 0.0
        acceptIndicator.opacity = 1.0
        acceptIndicator.anchors.horizontalCenterOffset = 0
        verticalGestureTranslate.y = incomingCallControl.controlsYOffset
        phoneHandleIcon.rotation = 0
        phoneHandleIcon.color = Qt.binding(function() { return palette.primaryColor })
    }

    Column {
        id: incomingCallControlColumn
        spacing: isPortrait ? (Theme.paddingLarge * 4) : Theme.paddingLarge
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: (hangupIndicator.height + spacing) / 2 + incomingCallControl.maxVerticalTranslate - Theme.paddingLarge * 3
        }
        transform: Translate {
            id: verticalGestureTranslate
            y: incomingCallControl.controlsYOffset
        }

        Row {
            id: acceptIndicator
            anchors.horizontalCenter: parent.horizontalCenter

            property real offset
            Icon {
                id: acceptIndicatorLeftArrow

                source: "image://theme/icon-m-arrow-left-green"
                anchors.verticalCenter: parent.verticalCenter
                transform: Translate {
                    x: -acceptIndicator.offset
                }
                opacity: (incomingCallControl.answering || hintsRunning) && !incomingCallControl.hangingUp ? 1.0 : 0.0
                Behavior on opacity { FadeAnimator {} }
            }

            Icon {
                id: phoneHandleIcon

                color: palette.primaryColor
                source: "image://theme/icon-l-dialer"
                anchors.verticalCenter: parent.verticalCenter
            }

            Icon {
                id: acceptIndicatorRightArrow
                source: "image://theme/icon-m-arrow-right-green"
                anchors.verticalCenter: parent.verticalCenter
                color: acceptIndicatorLeftArrow.color

                transform: Translate {
                    x: acceptIndicator.offset
                }

                opacity: (incomingCallControl.answering || hintsRunning) && !incomingCallControl.hangingUp ? 1.0 : 0.0
                Behavior on opacity { FadeAnimator {} }
            }
        }

        Icon {
            id: hangupIndicator

            property int offset
            anchors.horizontalCenter: parent.horizontalCenter
            source: "image://theme/icon-m-arrow-up-red"
            transform: Translate {
                y: -hangupIndicator.offset
            }

            opacity: (incomingCallControl.allowHangup && !incomingCallControl.answering && (incomingCallControl.hangingUp || hintsRunning)) ? 1.0 : 0.0
            Behavior on opacity { FadeAnimator {} }
        }
    }

    // These labels aren't inside the above column, because they need a different spacing,
    // and because they might mess up the vertical positioning of the column.
    // However, they are positioned so that they visually follow the items inside the column.
    Label {
        id: acceptHintLabel

        anchors {
            rightMargin: Theme.paddingLarge
            topMargin: phoneHandleIcon.height + Theme.paddingLarge
            bottomMargin: Theme.paddingLarge
            horizontalCenterOffset: acceptIndicator.anchors.horizontalCenterOffset
            verticalCenterOffset: -phoneHandleIcon.height / 2
        }

        transform: Translate {
            y: verticalGestureTranslate.y
        }
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Theme.fontSizeExtraSmall
        color: palette.secondaryColor

        //: Textual hint for horizontal accept call swipe gesture. Use <br> to break it to two or more lines.
        //% "Swipe left or right<br>to answer"
        text: qsTrId("voicecall-la-accept_swipe_hint")
        textFormat: Text.StyledText

        opacity: acceptHintTimer.running? 1.0 : 0.0
        Behavior on opacity { FadeAnimator {} }

        // Started when the user taps near the indicators.
        // This timer exists to simplify mouse handling, so that SwipeGestureArea doesn't need to steal
        // the mouse from the MouseArea below. (This is possible to an extent, but becomes messy
        // when a Flickable is also involved.)
        Timer {
            id: acceptHintPressTimer
            interval: 200
            onTriggered: {
                // Show hints after the timeout passed but the user hasn't started a gesture yet.
                if (!incomingCallControl.answering && !incomingCallControl.hangingUp) {
                    acceptHintTimer.restart()
                }
            }
        }

        // This timer is responsible for hiding the hints after a while.
        Timer {
            id: acceptHintTimer
            interval: 3000
        }

        states: [
            State {
                name: "portraitRinging"
                when: isPortrait && incomingCallControl.allowHangup

                AnchorChanges {
                    target: acceptHintLabel
                    anchors {
                        bottom: incomingCallControlColumn.top
                        horizontalCenter: parent.horizontalCenter
                    }
                }
            }, State {
                name: "portraitSilenced"
                when: isPortrait && !incomingCallControl.allowHangup

                AnchorChanges {
                    target: acceptHintLabel
                    anchors {
                        top: incomingCallControlColumn.top
                        horizontalCenter: parent.horizontalCenter
                    }
                }
            },
            State {
                name: "landscape"
                when: !isPortrait

                AnchorChanges {
                    target: acceptHintLabel
                    anchors {
                        verticalCenter: incomingCallControlColumn.verticalCenter
                        right: incomingCallControlColumn.left
                    }
                }
            }
        ]

    }

    // Area is deliberately larger than just the the gesture indicators,
    // so that the user gets the hints even if she/he didn't tap the indicators exactly.
    MouseArea {
        propagateComposedEvents: true
        width: parent.width
        height: incomingCallControlColumn.height
        anchors.bottom: hangupIndicatorHintArea.top
        enabled: hintsRunning

        onPressed: {
            // Make mouse handling simpler: don't accept the event, but still show the hints.
            acceptHintPressTimer.restart()
            mouse.accepted = false
        }
    }

    Label {
        id: hangupHintLabel

        anchors {
            leftMargin: Theme.paddingLarge
            topMargin: Theme.paddingLarge
            horizontalCenterOffset: acceptIndicator.anchors.horizontalCenterOffset
        }
        transform: Translate {
            y: verticalGestureTranslate.y
        }
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Theme.fontSizeExtraSmall
        color: palette.secondaryColor

        //: Textual hint for vertical silence/hangup swipe gesture. Use <br> to break it to two or more lines.
        //% "Swipe up<br>for more options"
        text: qsTrId("voicecall-la-hangup_swipe_hint")
        textFormat: Text.StyledText

        opacity: hangupHintTimer.running ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator {} }

        Timer {
            id: hangupHintPressTimer
            interval: 200
            onTriggered: {
                if (!incomingCallControl.answering && !incomingCallControl.hangingUp && incomingCallControl.allowHangup) {
                    hangupHintTimer.restart()
                }
            }
        }

        Timer {
            id: hangupHintTimer
            interval: 3000
        }

        states: [
            State {
                name: "portrait"
                when: isPortrait

                AnchorChanges {
                    target: hangupHintLabel
                    anchors {
                        top: incomingCallControlColumn.bottom
                        horizontalCenter: parent.horizontalCenter
                    }
                }
            }, State {
                name: "landscape"
                when: !isPortrait

                AnchorChanges {
                    target: hangupHintLabel
                    anchors {
                        verticalCenter: incomingCallControlColumn.verticalCenter
                        left: incomingCallControlColumn.right
                    }
                }
            }, State {
                name: "forcedHidden"
                when: !incomingCallControl.allowHangup

                PropertyChanges {
                    target: hangupHintLabel
                    opacity: 0.0
                }
            }

        ]
    }

    MouseArea {
        id: hangupIndicatorHintArea

        width: parent.width
        height: parent.height
                - (incomingCallControlColumn.height - hangupIndicator.height)
                + incomingCallControlColumn.spacing
        anchors {
            top: incomingCallControlColumn.top
            topMargin: incomingCallControlColumn.height
                       - hangupIndicator.height
                       + incomingCallControl.controlsYOffset
        }
        enabled: hintsRunning && incomingCallControl.allowHangup

        onPressed: {
            hangupHintPressTimer.restart()
            mouse.accepted = false
        }
    }

    Rectangle {
        id: acceptIndicatorRectangle

        width: parent.width
        height: parent.height
        color: "#00bb15"
        opacity: 0.0
        radius: Theme.paddingLarge
    }

    Column {
        id: silencedOptions

        y: Screen.height
        width: parent.width

        spacing: Theme.paddingMedium

        enabled: !menuLoader.menuOpen && (telephony.messagingPermitted || telephony.callingPermitted)
        opacity: enabled ? (1.0 - (incomingCallControl.answering ? incomingCallGesture.progress : 0.0)) : 0.0
        anchors.bottomMargin: isPortrait ? (Theme.paddingLarge * 2) : 0
        Behavior on opacity {
            enabled: !incomingCallControl.answering
            FadeAnimation { }
        }

        states: State {
            name: "silenced"
            when: main.state === "silenced"

            AnchorChanges {
                target: silencedOptions
                anchors.bottom: parent.bottom
            }
        }

        Label {
            leftPadding: Theme.horizontalPageMargin
            rightPadding: Theme.horizontalPageMargin
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            color: palette.highlightColor
            wrapMode: Text.Wrap

            opacity: main.state === "silenced" ? 1 : 0

            //% "Call silenced"
            text: qsTrId("voicecall-la-call_silenced")

            Behavior on opacity {
                FadeAnimation { duration: 300 }
            }
        }

        SilencedCallButtons {
            onSendMessageClicked: {
                //% "Select your message"
                menuLoader.open(qsTrId("voicecall-he-select_your_message"), messageReplyMenuComponent)
            }

            onReminderClicked: {
                //% "Remind me"
                menuLoader.open(qsTrId("voicecall-he-remind_me"), reminderMenuComponent)
            }

            onEndCallClicked: {
                if (!telephony.silencedCall) {
                    console.warn("Can't reject silenced call because there is no silenced call.")
                    return
                }
                if (main.state === "silenced") {
                    telephony.hangupCall(telephony.silencedCall)
                    main.hangupAnimation.complete()
                }
            }
        }

    }

    ParallelAnimation {
        id: resetAcceptAnimation

        NumberAnimation {
            target: acceptIndicator
            duration: incomingCallControl.resetAnimationDuration
            property: "anchors.horizontalCenterOffset"
            to: 0
        }
        NumberAnimation {
            target: phoneHandleIcon
            duration: incomingCallControl.resetAnimationDuration
            property: "rotation"
            to: 0
        }
        ColorAnimation {
            target: phoneHandleIcon
            duration: incomingCallControl.resetAnimationDuration
            property: "color"
            to: incomingCallControl.palette.primaryColor
        }
        NumberAnimation {
            target: acceptIndicatorRectangle
            duration: incomingCallControl.resetAnimationDuration
            property: "x"
            to: incomingCallControl.directionLeft ? incomingCallControl.width : (-incomingCallControl.width)
        }
        NumberAnimation {
            target: acceptIndicatorRectangle
            duration: incomingCallControl.resetAnimationDuration
            property: "opacity"
            to: 0.0
        }
    }

    ParallelAnimation {
        id: commitAcceptAnimation

        FadeAnimation {
            target: acceptIndicator
            duration: incomingCallControl.resetAnimationDuration
            property: "opacity"
            to: 0.0
        }
        NumberAnimation {
            target: acceptIndicatorRectangle
            duration: incomingCallControl.resetAnimationDuration
            property: "x"
            to: 0
        }
        NumberAnimation {
            target: acceptIndicatorRectangle
            duration: incomingCallControl.resetAnimationDuration
            property: "opacity"
            to: 0.0
        }
    }

    ParallelAnimation {
        id: resetHangupAnimation

        NumberAnimation {
            target: verticalGestureTranslate
            duration: incomingCallControl.resetAnimationDuration
            property: "y"
            to: 0
        }
        NumberAnimation {
            target: phoneHandleIcon
            duration: incomingCallControl.resetAnimationDuration
            property: "rotation"
            to: 0
        }
        NumberAnimation {
            target: silencedOptions
            duration: incomingCallControl.resetAnimationDuration
            property: "y"
            to: Screen.height
        }
    }

    ParallelAnimation {
        id: commitHangupAnimation

        NumberAnimation {
            target: verticalGestureTranslate
            duration: incomingCallControl.resetAnimationDuration
            property: "y"
            to: -incomingCallControl.maxVerticalTranslate * verticalSpeed
        }
        NumberAnimation {
            target: phoneHandleIcon
            duration: incomingCallControl.resetAnimationDuration
            property: "rotation"
            to: 30
        }
        NumberAnimation {
            target: silencedOptions
            duration: incomingCallControl.resetAnimationDuration
            property: "y"
            to: incomingCallControl.height - incomingCallControl.maxVerticalTranslate
        }
        NumberAnimation {
            target: phoneHandleIcon
            duration: incomingCallControl.resetAnimationDuration
            property: "rotation"
            to: 0.0
        }
    }

    // Workaround to not being able to disable parts of Qt Quick animation group
    // and not wanting to
    property int hintIndex
    property int hintCount: allowHangup ? 3 : 2 // if the call has already been silenced don't play the hangup hint
    property var hintAnimations: [phoneHandleHintAnimation, answerHintAnimation, hangupHintAnimation]
    property SequentialAnimation currentHintAnimation: hintsRunning ? hintAnimations[hintIndex] : null
    property bool hintsRunning: !commitAcceptAnimation.running && !commitHangupAnimation.running
    onHintsRunningChanged: if (!hintsRunning) hintIndex = 0

    function toggleHint() {
        hintIndex = (hintIndex + 1) % hintCount
    }

    // Phone handle wiggle
    SequentialAnimation {
        id: phoneHandleHintAnimation
        onStopped: if (hintsRunning) toggleHint()
        running: currentHintAnimation === phoneHandleHintAnimation
        paused: running && !incomingCallControl.playHints
        loops: 3

        RotationAnimator {
            target: phoneHandleIcon
            from: 0
            to: handleRotationAmplitude
            duration: handleRotationDuration/2
            easing.type: Easing.InQuad
        }
        RotationAnimator {
            target: phoneHandleIcon
            from: handleRotationAmplitude
            to: -handleRotationAmplitude
            duration: handleRotationDuration
            easing.type: Easing.OutInQuad
        }
        RotationAnimator {
            target: phoneHandleIcon
            from: -handleRotationAmplitude
            to: 0
            duration: handleRotationDuration/2
            easing.type: Easing.OutQuad
        }
    }

    SequentialAnimation {
        id: answerHintAnimation

        onStopped: if (hintsRunning) toggleHint()
        running: currentHintAnimation === answerHintAnimation
        paused: running && !incomingCallControl.playHints

        PauseAnimation { duration: 100 }
        ParallelAnimation {
            NumberAnimation {
                target: acceptIndicator
                property: "offset"
                easing.type: Easing.InQuad
                duration: arrowAnimationDuration
                from: 0.0
                to: arrowAnimationDistance
            }
            SequentialAnimation {
                PauseAnimation {
                    duration: arrowAnimationDuration * 2/3
                }
                ParallelAnimation {
                    FadeAnimation {
                        target: acceptIndicatorLeftArrow
                        duration: arrowAnimationDuration / 3
                        to: 0.0
                    }
                    FadeAnimation {
                        target: acceptIndicatorRightArrow
                        duration: arrowAnimationDuration / 3
                        to: 0.0
                    }
                }
            }
        }

        ParallelAnimation {
            FadeAnimation {
                target: acceptIndicatorLeftArrow
                duration: arrowAnimationDuration / 3
                to: 1.0
            }
            FadeAnimation {
                target: acceptIndicatorRightArrow
                duration: arrowAnimationDuration / 3
                to: 1.0
            }
            NumberAnimation {
                target: acceptIndicator
                property: "offset"
                easing.type: Easing.InQuad
                duration: arrowAnimationDuration/3
                from: -arrowAnimationDistance/3
                to: 0.0
            }
        }

        PauseAnimation { duration: 100 }
    }

    SequentialAnimation {
        id: hangupHintAnimation

        onStopped: if (hintsRunning) toggleHint()
        running: currentHintAnimation === hangupHintAnimation
        paused: running && !incomingCallControl.playHints

        ParallelAnimation {
            NumberAnimation {
                target: hangupIndicator
                property: "offset"
                easing.type: Easing.InQuad
                duration: arrowAnimationDuration
                from: 0.0
                to: (isPortrait ? 1 : 0.5) * arrowAnimationDistance
            }
            SequentialAnimation {
                PauseAnimation {
                    duration: arrowAnimationDuration * 2/3
                }
                FadeAnimation {
                    target: hangupIndicator
                    duration: arrowAnimationDuration / 3
                    to: 0.0
                }
            }
        }
        ScriptAction {
            script: hangupIndicator.offset = 0
        }
        ParallelAnimation {
            FadeAnimation {
                target: hangupIndicator
                duration: arrowAnimationDuration/3
                to: 1.0
            }
            NumberAnimation {
                target: hangupIndicator
                property: "offset"
                easing.type: Easing.InQuad
                duration: arrowAnimationDuration/3
                from: -arrowAnimationDistance/3
                to: 0.0
            }
        }
        PauseAnimation { duration: 100 }
    }
}
