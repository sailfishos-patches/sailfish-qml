import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import org.nemomobile.lipstick 0.1
import "../backgrounds"

EdgeLayer {
    id: launcherLayer

    // Show launcher above alarms
    property bool allowed
    property bool closedFromBottom
    property bool _wasPinning
    property real cellHeight
    property int _startPinPosition
    property Item _pinningHint
    readonly property bool closeFromEdge: pinned && _activePeek
    property Item indicatorApplicationForeground

    peekFilter {
        enabled: Lipstick.compositor.systemInitComplete
        onGestureTriggered: closedFromBottom = peekFilter.bottomActive
    }

    function hide() {
        if (window && window == Lipstick.compositor.topmostWindow)
            Lipstick.compositor.setCurrentWindow(Lipstick.compositor.obscuredWindow)
    }

    function resetPinning() {
        if (pinned) {
            pinned = false
            if (_pinningHint) {
                _pinningHint.hide()
            }
            hide()
        }
    }

    function _layerMoved(position) {
        if (_moving && Math.abs(position - _startPinPosition) > Theme.startDragDistance) {
            pinned = false
        }
    }

    function showHint() {
        if (!_moving) {
            hinting = true
        }
    }

    onExposedChanged: closedFromBottom = false
    on_EffectiveEdgeChanged: resetPinning()
    onVisibleChanged: if (!visible) resetPinning()

    onClosed: resetPinning()
    onPinnedChanged: {
        if (pinned) {
            if (pinningHintCounter.active)
                if (_pinningHint) {
                    _pinningHint.show()
                } else {
                    var hintComponent = Qt.createComponent("../launcher/PinnedLauncherHint.qml")
                    if (hintComponent.status === Component.Ready) {
                        _pinningHint = hintComponent.createObject(indicatorApplicationForeground)
                        _pinningHint.launcherAbsoluteExposure = Qt.binding(function() { return launcherLayer.absoluteExposure })
                        _pinningHint.closed.connect(pinningHintCounter.exhaust)
                    } else {
                        console.log("LauncherLayer failed create PinnedLauncherHint component", hintComponent.errorString())
                    }
                }
        } else {
            _wasPinning = true
            if (_pinningHint) {
                _pinningHint.hide()
            }
        }
    }
    onXChanged: if (_transposed) _layerMoved(x)
    onYChanged: if (!_transposed) _layerMoved(y)
    on_MovingChanged: {
        if (_moving) {
            pinned = false
        } else if (pinned) {
            pinPosition = _transposed ? x : y
        }
    }

    on_DragActiveChanged: {
        if (_dragActive) {
            _wasPinning = false
        } else if (!pinned && _wasPinning) {

            // after leaving pinning by default App Grid is opened,
            // but if user flicks down close instead
            var position = _transposed ? x : y
            var orientation = Lipstick.compositor.topmostWindowOrientation
            var invertedOrientation = orientation === Qt.InvertedPortraitOrientation || orientation == Qt.InvertedLandscapeOrientation
            var inverted = (!_transposed && !invertedOrientation) || (_transposed && invertedOrientation)
            if ((inverted && position > _startPinPosition) || (!inverted && position < _startPinPosition)) {
                Lipstick.compositor.setCurrentWindow(Lipstick.compositor.obscuredWindow)
            }
        }
    }

    childrenOpaque: false
    objectName: "launcherLayer"

    edge: PeekFilter.Bottom
    hintHeight: Theme.iconSizeLauncher * 2 + (Screen.sizeCategory >= Screen.Large ? Theme.paddingLarge*4 : 0)
    hintDuration: 600
    _finishDragWithAnimation: !pinned && !_wasPinning

    MenuBackground {
        z: -1
        anchors.fill: parent
        parent: launcherLayer.contentItem
    }

    Timer {
        // long-press timer to detect pinning
        interval: 400
        running: launcherLayer._moving && !launcherLayer.pinned && !launcherLayer.hinting
                 && (absoluteExposure > cellHeight/2 && (maximumExposure - absoluteExposure) > cellHeight/2)
        onRunningChanged: launcherLayer._startPinPosition = launcherLayer._transposed ? launcherLayer.x : launcherLayer.y
        onTriggered: {
            if (Lipstick.compositor.multitaskingHome) {
                launcherLayer.pinPosition = launcherLayer._transposed ? launcherLayer.x : launcherLayer.y
                launcherLayer.pinned = true
            }
        }
    }

    FirstTimeUseCounter {
        id: pinningHintCounter
        limit: 1
        key: "/desktop/lipstick-jolla-home/pinned_launcher_hint_count"
        ignoreSystemHints: true
    }
}
