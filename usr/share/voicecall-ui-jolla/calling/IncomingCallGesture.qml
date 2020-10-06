/*
 * Copyright (c) 2012 - 2020 Jolla Ltd.
 * Copyright (c) 2019 - 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0

SwipeGestureArea {
    id: incomingCallGesture

    // Just the visual interface, don't put any engine or model specific code here!!

    property alias animationRunning: incomingCallControl.animationRunning
    property alias allowHangup: incomingCallControl.allowHangup
    readonly property int answerThreshold: Math.min(width, height) * 0.25
    readonly property int rejectThreshold: answerThreshold

    readonly property real progress: {
        if (!gestureInProgress) {
            return 0.0
        }

        var threshold = direction === SwipeGestureArea.Up ? rejectThreshold : answerThreshold
        var amount = Math.max(0, threshold - Math.abs(swipeAmount))
        if ((direction & SwipeGestureArea.DirectionVertical) && swipeAmount >= 0.0)
            amount = threshold
        return Math.max(0.0, (threshold - Math.min(amount, threshold)) / threshold)
    }

    signal answerGestureTriggered
    signal hangupGestureTriggered

    function resetGestures() {
        incomingCallControl.reset()
        incomingCallGesture.endGesture()
    }

    function resetGesturesWithDelay() {
        resetTimer.start()
    }

    anchors.fill: parent
    allowedDirections: allowHangup
                       ? (SwipeGestureArea.DirectionHorizontal | SwipeGestureArea.DirectionUp)
                       : SwipeGestureArea.DirectionHorizontal
    thresholdX: Theme.startDragDistance
    thresholdY: Theme.startDragDistance

    onGestureInProgressChanged: {
        if (direction & SwipeGestureArea.DirectionHorizontal) {
            if (gestureInProgress) {
                incomingCallControl.startAcceptGesture()
            } else if (Math.abs(swipeAmount) >= answerThreshold) {
                incomingCallControl.commitAcceptGesture()
                incomingCallGesture.answerGestureTriggered()
            } else {
                incomingCallControl.stopAcceptGesture()
            }
        } else {
            if (gestureInProgress) {
                incomingCallControl.startRejectGesture()
            } else if (Math.abs(swipeAmount) >= rejectThreshold) {
                incomingCallControl.commitRejectGesture()
                incomingCallGesture.hangupGestureTriggered()
            } else {
                incomingCallControl.stopRejectGesture()
            }
        }
    }

    IncomingCallControl {
        id: incomingCallControl
        swipeAmount: incomingCallGesture.swipeAmount
        playHints: !incomingCallGesture.gestureInProgress
        answerHighlightColor: callingView.answerHighlightColor
        rejectHighlightColor: callingView.rejectHighlightColor
        answering: incomingCallGesture.gestureInProgress && (incomingCallGesture.direction & SwipeGestureArea.DirectionHorizontal)
        hangingUp: incomingCallGesture.gestureInProgress && (incomingCallGesture.direction & SwipeGestureArea.DirectionVertical)
        directionLeft: incomingCallGesture.direction === SwipeGestureArea.DirectionLeft
        progress: incomingCallGesture.progress
    }

    Timer {
        id: resetTimer
        interval: 400
        onTriggered: incomingCallGesture.resetGestures()
    }

    // Lock orientation while the control is animating to avoid visual inconsistencies
    states: [
        State {
            when: incomingCallControl.animationRunning && isPortrait

            PropertyChanges {
                target: main
                allowedOrientations: Orientation.PortraitMask

            }
        }, State {
            when: incomingCallControl.animationRunning && !isPortrait

            PropertyChanges {
                target: main
                allowedOrientations: Orientation.LandscapeMask

            }
        }
    ]
}
