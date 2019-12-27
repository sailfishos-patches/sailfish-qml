import QtQuick 2.0
import QtQuick.Window 2.1 as QtQuick
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1
import Sailfish.Lipstick 1.0

Layer {
    id: edgeLayer

    property alias edgeFilter: peekFilter
    property MouseArea interactiveArea

    property real _bottomEdge
    property real _rightEdge
    property real _horizontalProgress
    property real _verticalProgress
    property real _hintProgress
    property real _thresholdOffset
    property alias hinting: hintAnimation.running
    property alias hintHeight: hintShowAnimation.to
    property alias hintDuration: hintPauseAnimation.duration

    property real margin
    property real absoluteExposure
    property real maximumExposure
    property real exposure

    property bool peekingAtHome
    property bool _activePeek
    property bool _smoothClip
    property bool _effectiveActive

    onActiveChanged: {
        _smoothClip = clip
        _effectiveActive = active
        _smoothClip = false
    }

    property int edge: PeekFilter.Bottom
    readonly property int _effectiveEdge: {
        // Left (1 << 0), Top (1 << 1), Right (1 << 2), Bottom (1 << 3)
        switch (QtQuick.Screen.angleBetween(
                    Lipstick.compositor.topmostWindowOrientation,
                    QtQuick.Screen.primaryOrientation)) {
        case 90: // Top -> Right
            return edge <= PeekFilter.Right ? edge << 1 : edge >> 3
        case 180: // Top -> Bottom
            return edge <= PeekFilter.Top ? edge << 2 : edge >> 2
        case 270: // Top -> Left
            return edge <= PeekFilter.Left ? edge << 3 : edge >> 1
        default: // Top -> Top
            return edge
        }
    }

    property bool _showActive: (edge == PeekFilter.Left && peekFilter.leftActive)
                || (edge == PeekFilter.Top && peekFilter.topActive)
                || (edge == PeekFilter.Right && peekFilter.rightActive)
                || (edge == PeekFilter.Bottom && peekFilter.bottomActive)
    property bool _hideActive: (edge == PeekFilter.Left && peekFilter.rightActive)
                || (edge == PeekFilter.Top && peekFilter.bottomActive)
                || (edge == PeekFilter.Right && peekFilter.leftActive)
                || (edge == PeekFilter.Bottom && peekFilter.topActive)

    property bool _dragActive: interactiveArea && interactiveArea.drag.active
    on_DragActiveChanged: {
        if (_dragActive) {
            _thresholdOffset = _hintProgress
            hintAnimation.stop()
            peekFilter.gestureStarted()
        } else {
            var threshold = Math.max(peekFilter.threshold, _thresholdOffset)
            var dx = active ? x : x - _rightEdge
            var dy = active ? y : y - _bottomEdge
            if (Math.abs(dx) > threshold || Math.abs(dy) > threshold) {
                peekFilter.gestureTriggered()
            } else {
                peekFilter.gestureCanceled()
            }
        }
    }

    onPeekingChanged: _activePeek = active && (peekingAtHome || peeking)
    onPeekingAtHomeChanged: _activePeek = active && (peekingAtHome || peeking)

    anchors { fill: null }

    mergeWindows: false
    clip: edgeLayer._showActive
                || edgeLayer._hideActive
                || edgeLayer._smoothClip
                || (interactiveArea && interactiveArea.drag.active)
                || gestureTransition.running
                || visibleTransition.running
                || hintAnimation.running
    width: parent.width
    height: parent.height

    peekFilter.onGestureTriggered: edgeFilter.gestureTriggered()

    // Workaround for JB#10277
    // changing enabled sometimes triggers an assert
    //enabled: root.edgeLayer.active

    states: [
        State {
            name: "dragging"
            when: edgeLayer._dragActive
            PropertyChanges {
                target: edgeLayer
                x: edgeLayer.x
                y: edgeLayer.y
                exposure: Math.min(1, absoluteExposure / peekFilter.threshold)
            }
        }, State {
            name: "showing"
            when: !edgeLayer._effectiveActive && (edgeLayer._showActive || hintAnimation.running)
            PropertyChanges {
                target: edgeLayer
                x: edgeLayer._rightEdge - edgeLayer._horizontalProgress
                y: edgeLayer._bottomEdge - edgeLayer._verticalProgress
                exposure: Math.min(1, absoluteExposure / peekFilter.threshold)
            }
        } , State {
            name: "peeking"
            when: edgeLayer._activePeek
            PropertyChanges {
                target: edgeLayer
                x: 0
                y: 0
                exposed: true
                exposure: 1
            }
        }, State {
            name: "hidden"
            when: !edgeLayer._effectiveActive && !edgeLayer._showActive
            PropertyChanges {
                target: edgeLayer
                x: edgeLayer._rightEdge
                y: edgeLayer._bottomEdge
                exposure: 0
            }
        }, State {
            name: "hiding"
            when: edgeLayer._effectiveActive && edgeLayer._hideActive
            PropertyChanges {
                target: edgeLayer
                x: edgeLayer._horizontalProgress
                y: edgeLayer._verticalProgress
                exposure: Math.min(1, absoluteExposure / peekFilter.threshold)
            }
        }, State {
            name: "closing"
            when: edgeLayer.closing && !edgeLayer._hideActive
            PropertyChanges {
                target: edgeLayer
                x: 0
                y: 0
                exposure: 0
            }
        }, State {
            name: "visible"
            when: edgeLayer._effectiveActive && !edgeLayer._hideActive
            PropertyChanges {
                target: edgeLayer
                x: 0
                y: 0
                exposure: 1
            }
        }
    ]

    transitions: [
        Transition {
            id: gestureTransition
            to: "visible,hidden,peeking"
            from: "showing,hiding,dragging"
            NumberAnimation {
                target: edgeLayer
                property: "x"
                duration: 300
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: edgeLayer
                property: "y"
                duration: 300
                easing.type: Easing.OutQuad
            }
            PropertyAction {
                target: edgeLayer
                property: "_hintProgress"
                value: 0
            }
        }, Transition {
            id: visibleTransition
            to: "visible,hidden"
            from: "hidden,visible"
            NumberAnimation {
                target: edgeLayer
                property: "x"
                duration: 400
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: edgeLayer
                property: "y"
                duration: 400
                easing.type: Easing.InOutQuad
            }
            PropertyAction {
                target: edgeLayer
                property: "_hintProgress"
                value: 0
            }
        }
    ]

    SequentialAnimation {
        id: hintAnimation

        running: false
        NumberAnimation {
            id: hintShowAnimation
            target: edgeLayer
            property: "_hintProgress"
            duration: 300
            to: Theme.iconSizeLauncher * 2
            easing.type: Easing.InOutQuad
        }
        PauseAnimation { id: hintPauseAnimation; duration: 2000 }
        NumberAnimation {
            target: edgeLayer
            property: "_hintProgress"
            duration: 300
            to: 0
            easing.type: Easing.InOutQuad
        }
    }

    PeekFilter {
        id: peekFilter

        leftEnabled: (edgeLayer.edge == PeekFilter.Left && !edgeLayer.active)
                    || (edgeLayer.edge == PeekFilter.Right && edgeLayer.active)
        topEnabled: (edgeLayer.edge == PeekFilter.Top && !edgeLayer.active)
                    || (edgeLayer.edge == PeekFilter.Bottom && edgeLayer.active)
        rightEnabled: (edgeLayer.edge == PeekFilter.Right && !edgeLayer.active)
                    || (edgeLayer.edge == PeekFilter.Left && edgeLayer.active)
        bottomEnabled: (edgeLayer.edge == PeekFilter.Bottom && !edgeLayer.active)
                    || (edgeLayer.edge == PeekFilter.Top && edgeLayer.active)

        states: [
            State {
                name: "bottom"
                when: edgeLayer._effectiveEdge == PeekFilter.Bottom && edgeLayer.interactiveArea != null
                PropertyChanges {
                    target: edgeLayer
                    _bottomEdge: edgeLayer.height - edgeLayer.margin
                    _verticalProgress: Math.min(
                                peekFilter.absoluteProgress + edgeLayer._hintProgress,
                                edgeLayer.height - edgeLayer.margin)
                    absoluteExposure: edgeLayer._bottomEdge - edgeLayer.y
                    maximumExposure: edgeLayer.height - edgeLayer.margin
                }
                PropertyChanges {
                    target: edgeLayer.interactiveArea.drag
                    axis: Drag.YAxis
                    minimumY: 0
                    maximumY: edgeLayer.height - edgeLayer.margin
                }
            }, State {
                name: "left"
                when: edgeLayer._effectiveEdge == PeekFilter.Left && edgeLayer.interactiveArea != null
                PropertyChanges {
                    target: edgeLayer
                    _rightEdge: -edgeLayer.width + edgeLayer.margin
                    _horizontalProgress: -Math.min(
                                peekFilter.absoluteProgress + edgeLayer._hintProgress,
                                edgeLayer.width - edgeLayer.margin)
                    absoluteExposure: edgeLayer.x - edgeLayer._rightEdge
                    maximumExposure: edgeLayer.width - edgeLayer.margin
                }
                PropertyChanges {
                    target: edgeLayer.interactiveArea.drag
                    axis: Drag.XAxis
                    minimumX: -edgeLayer.width + edgeLayer.margin
                    maximumX: 0
                }
            }, State {
                name: "top"
                when: edgeLayer._effectiveEdge == PeekFilter.Top && edgeLayer.interactiveArea != null
                PropertyChanges {
                    target: edgeLayer
                    _bottomEdge: -edgeLayer.height + edgeLayer.margin
                    _verticalProgress: -Math.min(
                                peekFilter.absoluteProgress + edgeLayer._hintProgress,
                                edgeLayer.height - edgeLayer.margin)
                    absoluteExposure: edgeLayer.y - edgeLayer._bottomEdge
                    maximumExposure: edgeLayer.height - edgeLayer.margin
                }
                PropertyChanges {
                    target: edgeLayer.interactiveArea.drag
                    axis: Drag.YAxis
                    minimumY: -edgeLayer.height + edgeLayer.margin
                    maximumY: 0
                }
            }, State {
                name: "right"
                when: edgeLayer._effectiveEdge == PeekFilter.Right && edgeLayer.interactiveArea != null
                PropertyChanges {
                    target: edgeLayer
                    _rightEdge: edgeLayer.width - edgeLayer.margin
                    _horizontalProgress: Math.min(
                                peekFilter.absoluteProgress + edgeLayer._hintProgress,
                                edgeLayer.width - edgeLayer.margin)
                    absoluteExposure: edgeLayer._rightEdge - edgeLayer.x
                    maximumExposure: edgeLayer.width - edgeLayer.margin
                }
                PropertyChanges {
                    target: edgeLayer.interactiveArea.drag
                    axis: Drag.XAxis
                    minimumX: 0
                    maximumX: edgeLayer.width - edgeLayer.margin
                }
            }
        ]
    }
}
