import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1

Layer {
    id: layer

    property bool closingToHome
    property bool delaySwitch
    property bool exclusive
    property bool _closeDeferred
    property bool _closeDismissedWindow
    property Item _ignoreCloseFor
    property bool locked
    property bool snapshotInUse
    property bool _effectiveDelaySwitch: delaySwitch || snapshotInUse

    readonly property int closingWindowId: (peekFilter.topActive || (closing && _closeDismissedWindow))
                && window
            ? window.window.windowId
            : 0

    signal closeWindow(Item window)
    signal cacheWindow(Item window)
    signal queueWindow(Item window)
    signal windowShown(Item window)
    signal aboutToShowWindow(Item window)
    signal requestFocus()

    enabled: active
    delayClose: peekingAtHome || snapshotInUse
    transitioning: showAnimation.running || showAnimation.retries > 0

    peekFilter.onGestureTriggered: _closeDismissedWindow = peekFilter.topActive

    onClosed: {
        _closeDeferred = false
        switchTimer.execute = false

        if (closing || closingToHome || (_effectiveDelaySwitch && !locked
                    && contentItem.children.length > (window ? 1 : 0))) {
            // If the other PeekArea is closing or the window switch is being deferred; remove the
            // outgoing window from the scene but do the actual close later.
            if (window && window != _ignoreCloseFor) {
                _closeDeferred = true
                window.parent = null
                window.exposed = false
            }
            return
        }

        var previousWindow = window

        showAnimation.cancel()
        opacity = 0

        // Show the item at the head of the queue.
        var tail = window && window != _ignoreCloseFor
                ? contentItem.lastItemAfter(window)
                : contentItem.lastItem
        if (tail && !locked) {
            _showWindow(tail)
        } else {
            if (active && (locked || window != _ignoreCloseFor)) {
                Lipstick.compositor.setCurrentWindow(Lipstick.compositor.obscuredWindow, true)
            }
            if (window && window != _ignoreCloseFor) {
                window.parent = null
                window = null
            }
        }

        if (previousWindow && window != previousWindow) {
            previousWindow.exposed = false
            if (previousWindow == _ignoreCloseFor) {
                previousWindow.visible = false
            } else {
                previousWindow.parent = null
                if (_closeDismissedWindow) {
                    closeWindow(previousWindow)
                }
            }
        } else if (previousWindow && locked) {
            previousWindow.exposed = false
            previousWindow.visible = false
        }

        _closeDismissedWindow = false
        _ignoreCloseFor = null
    }

    onAboutToClose: {
        if (mergeWindows && !closingToHome) {
            cacheWindow(window)
        }
    }

    onCompleteTransitions: {
        showAnimation.complete()
        opacity = 1
    }

    onLockedChanged: {
        if (closing || closingToHome || _closeDeferred) {
        } else if (locked && window) {
            _ignoreCloseFor = window
            close()
        } else if (!locked && contentItem.lastItem) {
            _showWindow(contentItem.lastItem)
        }
    }

    on_EffectiveDelaySwitchChanged: {
        if (!_effectiveDelaySwitch && (_closeDeferred
                    || window == _ignoreCloseFor
                    || window != contentItem.lastItem)) {
            switchTimer.execute = true
        } else if (_effectiveDelaySwitch) {
            switchTimer.execute = false
        }
    }

    // Calling closed() from onDelaySwitchChanged can create a non-recursing binding loop
    // in other layers.  The timer decouples the closed() from the property change
    // handler so QML doesn't detect a loop and abort evaluation.
    Timer {
        id: switchTimer

        property bool execute
        running: execute

        interval: 0
        onTriggered: {
            if (execute) {
                execute = false
                closed()
            }
        }
    }

    function quickShow(w) {
        show(w, true)
    }

    function show(w, quick) {
        if (quick === undefined) quick = false
        if (Lipstick.compositor.debug) {
            console.log("StackLayer: Show window: \"", w, "\" current window: \"", window, "\"")
            console.log("StackLayer: Show active layer: \"", layer, "\" is active: ", active)
            console.log("StackLayer: Show window closing:", closing, "closingToHome:", closingToHome)
            console.log("StackLayer: Show window close deferred:", _closeDeferred, "last content item:", contentItem.lastItem)
        }

        // Canceled close gesture -> fully fade in
        if (w == window) {
            if (closing || closingToHome || _closeDeferred) {
                _ignoreCloseFor = w
            }
            if (window.parent == contentItem) {
                requestFocus()
                Lipstick.compositor.setCurrentWindow(window)
                return
            }
        }

        if (exclusive) {
            // shallow copy of contentItem.children
            var queued = []
            while (queued.length < contentItem.children.length)
                queued.push(contentItem.children[queued.length])

            // If the layer is exclusive remove all other queued windows before queuing a new
            // one.
            var head
            while (queued.length) {
                head = queued.shift()
                if (head != window && head != w) {
                    head.exposed = false
                    head.parent = null
                }
            }
        }
        queueWindow(w)
        if (w.parent != contentItem) {
            w.exposed = false
            return
        }

        if (w != contentItem.lastItem) {
            // The current window has priority and the new one won't be shown until it is
            // dismissed.  Hide/minimize the new window in the meantime.
            w.exposed = false
            w.visible = false
        } else if (!closing && !closingToHome && !_closeDeferred) {
            if (window && window != w) {
                // If another window was showing fade it out before showing the new one.
                w.visible = false
                if (!exclusive) {
                     // Don't actually close the current window when the transition finishes.
                    _ignoreCloseFor = window
                }
                if ((locked || !windowVisible) && !closing) {
                    closed()
                } else {
                    close()
                }
            } else {
                _showWindow(w, quick)
            }
        } else {
            // The new window has priority but the old one is still visible.  Don't show the
            // new window yet but leave its visibility as FullScreen.
            w.visible = false
        }
    }

    function hide(w, direct) {
        if (!w) {
            if (!window) {
                return
            }

            w = window
        }

        if (!exposed || !windowVisible || direct) {
            if (w == window) {
                showAnimation.cancel()
                opacity = 0
                if (!direct && w.parent == contentItem) {
                    w.exposed = false
                }

                var tail = contentItem.lastItemAfter(w)
                if (tail && !closing && !closingToHome && !_closeDeferred) {
                    _showWindow(tail)
                }

                if (window == w) {
                    if (Lipstick.compositor.topmostWindow == w) {
                        Lipstick.compositor.setCurrentWindow(Lipstick.compositor.obscuredWindow, true)
                    }
                    window = null
                }

                w.parent = null
            } else if (w.parent == contentItem) {
                if (!direct) {
                    w.exposed = false
                }
                w.parent = null
            }
        } else if (w == window) {
            _ignoreCloseFor = null
            if (!closingToHome && !_closeDeferred && w == contentItem.lastItem) {
                close()
            }
            showAnimation.cancel()
        } else if (w.parent == contentItem) {
            w.parent = null
        }
    }

    function _showWindow(w, quick) {
        switchTimer.execute = false
        if (quick === undefined) quick = false

        if (Lipstick.compositor.debug) {
            console.log("StackLayer: About to show window \"", w ,"\" layer: \"", layer, "\"")
            console.log("StackLayer: Are we locked: ", locked, "effective delay switch:", _effectiveDelaySwitch, "delay switch:", delaySwitch)
            console.log("StackLayer: Snapshot in use:", snapshotInUse, "last content item:", contentItem.lastItem)
        }

        aboutToShowWindow(w)
        requestFocus()

        if (locked) {
            w.exposed = false
            window = w
            return
        }

        if (_effectiveDelaySwitch) {
            if (w == window) {
                _ignoreCloseFor = w
            }
            w.visible = false
            return
        }

        opacity = 0

        windowShown(w)

        showAnimation.retries = 0

        // This prevents the opaque binding from evaluating to true briefly when the window
        // becomes active but before the fade in animation is started.
        transitionIsPending = true

        window = w
        Lipstick.compositor.setCurrentWindow(w)

        // Run the raise animation if the compositor window is visible (windowVisible) and
        // the application layer is not obscured by another layer i.e. either setCurrentWindow
        // successfully made it the active/topmost window (active) or there is a layer above but
        // which not fully opaque (peekedAt). If those conditions aren't met the layer is not
        // visible so the opacity should be set to 1.0 so its visible immediately when the layer
        // above goes away.
        if (windowVisible && (active || peekedAt)) {
            delayAnimation.duration = quick ? 0 : 150
            showAnimation.restart()
        } else {
            opacity = 1.0
        }

        transitionIsPending = false

        w.exposed = Qt.binding(function () { return layer.windowVisible })
        w.visible = true
    }

    peekFilter {
        onGestureStarted: {
            if (layer.mergeWindows) {
                layer.cacheWindow(layer.window)
            }
        }
    }

    SequentialAnimation {
        id: showAnimation
        running: false // don't run on startup...

        property int retries

        function cancel() {
            stop()
            retries = 0
        }

        // Allow some time for the application to respond to the visibility change before
        // capturing the fade in snapshot.  This is the same amount of time it takes the
        // switcher scale animation to complete so the animations will appear sequential.

        PauseAnimation { id: delayAnimation; duration: 150 }
        ScriptAction {
            script: {
                if (active) {
                    if (layer.window.mapped || ++showAnimation.retries >= 4) {
                        showAnimation.retries = 0
                        if (layer.mergeWindows) {
                            layer.cacheWindow(layer.window)
                        }
                    } else {
                        // If the window has not yet been redrawn wait for up to a second for
                        // the window to be mapped.  If it's still not mapped by that time just
                        // fade in anyway, a not responding dialog will probably follow soon after
                        // to explain the black window.
                        delayAnimation.duration = 150
                        showAnimation.restart()
                    }
                } else {
                    showAnimation.retries = 0
                }
            }
        }
        FadeAnimator {
            target: layer
            duration: 300
            from: 0.0
            to: 1.0
            easing.type: Easing.InOutQuad
        }
    }

    Connections {
        target: layer.window
        onMappedChanged: {
            if (layer.window.mapped && showAnimation.retries > 0) {
                delayAnimation.complete()
            }
        }
    }
}
