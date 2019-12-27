import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import org.nemomobile.lipstick 0.1

Item {
    id: peekArea

    property alias transitionItem: transitionItem
    property alias snapshotSource: snapshot
    property alias underlayItem: underlay
    property alias contentItem: content
    property alias overlayItem: overlay
    property alias contentOpacity: snapshot.opacity

    signal aboutToClose
    signal closed

    property alias peekFilter: peekFilter

    property alias quickAppToggleGestureExceeded: peekFilter.extraGestureThresholdExceeded
    readonly property bool peeking: resetAnimation.running || peekFilter.active
    property bool closing
    property bool delayClose
    property bool exposed: true
    property bool contentVisible: Lipstick.compositor.visible && exposed
    property bool closeAnimating

    default property alias _data: content.data

    visible: exposed
    clip: peeking
    anchors.fill: parent

    onDelayCloseChanged: {
        if (!delayClose && closing) {
            closeTimer.execute = true
        } else {
            closeTimer.execute = false
        }
    }

    function close() {
        if (!delayClose && !resetAnimation.running && !peekFilter.active) {
            if (contentVisible) {
                closing = true
                closeAnimating = true
                aboutToClose()
                clipEndAnimation.duration = 600
                _startFade()
            } else {
                closing = false
                closed()
            }
        } else {
            closing = true
        }
    }

    function completeTransitions() {
        resetAnimation.stop()
    }

    function _startFade() {
        fadeOut.from = peekArea.opacity
        opacityAnimation.complete()
        resetAnimation.restart()
    }

    Timer {
        id: closeTimer

        property bool execute

        running: execute

        interval: 0
        onTriggered: if (execute) { execute = false; peekArea.close() }
    }

    Behavior on opacity {
        id: opacityBehavior
        enabled: false
        SmoothedAnimation { id: opacityAnimation; duration: 300; velocity: 1000 / duration }
    }

    Item {
        id: snapshot

        x: -peekArea.x
        y: -peekArea.y
        width: peekArea.parent.width
        height: peekArea.parent.height

        Item {
            id: underlay
            anchors.fill: snapshot
        }

        StackItem {
            id: content
            anchors.fill: snapshot
        }

        Item {
            id: overlay
            anchors.fill: snapshot
        }
    }

    Item {
        id: transitionItem
        anchors.fill: snapshot
    }


    PeekAreaFilter {
        id: peekFilter

        onGestureStarted: {
            if (windowTopActive || windowBottomActive) {
                clipEndAnimation.to = content.height
            } else if (windowLeftActive || windowRightActive) {
                clipEndAnimation.to = content.width
            }
            opacityBehavior.enabled = true
        }
        onGestureCanceled: {
            opacityBehavior.enabled = false
            if (peekFilter.closing) {
                peekArea.closeAnimating = true
                clipEndAnimation.duration = 400
            } else {
                clipEndAnimation.duration = 200
                clipEndAnimation.to = 0
            }

            peekArea._startFade()
        }
        onGestureTriggered: {
            opacityBehavior.enabled = false
            peekArea.closing = true
            peekArea.closeAnimating = true
            clipEndAnimation.duration = 300 * (clipEndAnimation.to - peekFilter.absoluteProgress) / clipEndAnimation.to
            peekArea._startFade()
        }

        states: [
            State {
                name: "peeking"
                PropertyChanges {
                    target: peekArea
                    opacity: (1 - Math.max(peekArea.peekFilter.progress - Theme.highlightBackgroundOpacity, 0) / 0.7)
                }
            }, State {
                name: "left-peek"; extend: "peeking"; when: peekFilter.windowLeftActive
                PropertyChanges { target: peekArea.anchors; leftMargin: peekFilter.absoluteProgress }
            }, State {
                name: "top-peek"; extend: "peeking"; when: peekFilter.windowTopActive
                PropertyChanges { target: peekArea.anchors; topMargin: peekFilter.absoluteProgress }
            }, State {
                name: "right-peek"; extend: "peeking"; when: peekFilter.windowRightActive
                PropertyChanges { target: peekArea.anchors; rightMargin: peekFilter.absoluteProgress }
            }, State {
                name: "bottom-peek"; extend: "peeking"; when: peekFilter.windowBottomActive
                PropertyChanges { target: peekArea.anchors; bottomMargin: peekFilter.absoluteProgress }
            }, State {
                when: !peekFilter.active
                PropertyChanges { target: peekArea; explicit: true; opacity: peekArea.opacity }
                PropertyChanges {
                    target: peekArea.anchors
                    explicit: true
                    topMargin: peekArea.anchors.topMargin
                    leftMargin: peekArea.anchors.leftMargin
                    rightMargin: peekArea.anchors.rightMargin
                    bottomMargin: peekArea.anchors.bottomMargin
                }
            }
        ]
    }

    ParallelAnimation {
        id: resetAnimation
        running: false

        NumberAnimation {
            id: clipEndAnimation

            easing.type: Easing.InOutQuad
            target: peekArea.anchors
            property: {
                if (peekFilter.windowLeftActive) { return "leftMargin" }
                else if (peekFilter.windowTopActive) { return "topMargin" }
                else if (peekFilter.windowRightActive) { return "rightMargin" }
                else if (peekFilter.windowBottomActive) { return "bottomMargin" }
                else { return "" }
            }
        }

        FadeAnimator {
            id: fadeOut
            target: peekArea
            duration: clipEndAnimation.duration
            to: peekArea.closing ? 0 : 1
            easing.type: Easing.InOutQuad
        }

        onStopped: {
            clipEndAnimation.to = 0
            peekArea.opacity = 1.0
            peekArea.anchors.topMargin = 0
            peekArea.anchors.leftMargin = 0
            peekArea.anchors.rightMargin = 0
            peekArea.anchors.bottomMargin = 0

            if (peekArea.closeAnimating) {
                peekArea.closing = false
                peekArea.closed()
                peekArea.closeAnimating = false
            } else if (closing) {
                peekArea.close()
            } else {
                peekFilter.gestureReset()
            }
        }
    }
}
