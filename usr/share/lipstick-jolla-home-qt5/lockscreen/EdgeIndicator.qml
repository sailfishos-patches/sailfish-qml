import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1

Image {
    id: indicator

    property bool active
    property bool peeking
    property real peekProgress
    property bool hinting: false
    property real offset: -width
    property real threshold: Theme.itemSizeLarge / 2
    property bool locked
    property bool fadeoutWhenHiding

    property real _peekProgressScale: 0.4
    property real _initialIconPos

    function reset() {
        state = "hidden"
        hinting = false
    }

    state: "hidden"

    anchors {
        verticalCenter: parent.verticalCenter
        margins: offset
    }

    source: "image://theme/graphics-edge-swipe-arrow"
    rotation: 90
    width: sourceSize.width
    height: sourceSize.height
    enabled: peeking || hinting

    onPeekingChanged: {
        if (peeking) {
            hinting = false
        }
    }

    states: [
        State {
            name: "peeking"
            when: indicator.peeking
            StateChangeScript {
                script: {
                    _initialIconPos = indicator.offset
                }
            }
            PropertyChanges {
                target: indicator
                offset: {
                    if (_initialIconPos < 0) {
                        // accelerate icon movement from offscreen
                        var peekedRatio = (indicator.peekProgress * indicator._peekProgressScale) / (lockScreen.peekFilter.threshold * indicator._peekProgressScale)
                        var iconPosChange = indicator.width * peekedRatio
                        return (peekProgress * _peekProgressScale) + _initialIconPos + iconPosChange
                    } else {
                        return (peekProgress * _peekProgressScale)
                    }
                }
                opacity: (offset + indicator.width) / (lockScreen.peekFilter.threshold * indicator._peekProgressScale)
            }
        }, State {
            name: "hinting"
            when: indicator.hinting
            PropertyChanges {
                target: indicator
                offset: Screen.sizeCategory <= Screen.Medium ? 0 : indicator.threshold
                opacity: (offset + indicator.width) / indicator.threshold
            }
        }, State {
            name: "triggered"
            when: !indicator.locked && indicator.active
            PropertyChanges {
                target: indicator
                opacity: 0.0
                offset: lockScreen.peekFilter.threshold * 0.8
            }
        }, State {
            name: "fadedOut"
            when: !indicator.hinting && !indicator.peeking && fadeoutWhenHiding
            PropertyChanges {
                target: indicator
                opacity: 0.0
                offset: offset
            }
        }, State {
            name: "hidden"
            extend: "fadedOut"
            when: !indicator.hinting && !indicator.peeking && !fadeoutWhenHiding
            PropertyChanges {
                target: indicator
                offset: -indicator.width
            }
        }
    ]

    transitions: [
        Transition {
            from: "hidden,fadedOut"
            to: "hinting"
            SequentialAnimation {
                alwaysRunToEnd: true
                ParallelAnimation {
                    FadeAnimation {
                        target: indicator
                        duration: 400
                        from: Theme.opacityHigh
                        to: 1.0
                    }

                    SmoothedAnimation {
                        target: indicator
                        properties: "offset"
                        duration: 700
                        velocity: 1000 / duration
                    }
                }
                PauseAnimation { duration: 1500 }
                ScriptAction {
                    script: {
                        indicator.hinting = false
                    }
                }
            }
        }, Transition {
            from: "peeking"
            to: "triggered"
            SequentialAnimation {
                SmoothedAnimation {
                    target: indicator
                    properties: "offset"
                    duration: 400
                    velocity: 1000 / duration
                }
                FadeAnimation {
                    target: indicator
                    duration: 400
                }
                ScriptAction { script: indicator.reset(true) }
            }
        }, Transition {
            from: "peeking,hinting"
            to: "hidden"
            SequentialAnimation {
                SmoothedAnimation {
                    target: indicator
                    properties: "offset"
                    duration: 400
                    velocity: 1000 / duration
                }
                PropertyAction { target: indicator; property: "opacity" }
                ScriptAction { script: indicator.reset(true) }
            }
        }, Transition {
            from: "peeking,hinting"
            to: "fadedOut"
            SequentialAnimation {
                FadeAnimation {
                    target: indicator
                    duration: 400
                }
                ScriptAction { script: indicator.reset(true) }
            }
        }
    ]
}
