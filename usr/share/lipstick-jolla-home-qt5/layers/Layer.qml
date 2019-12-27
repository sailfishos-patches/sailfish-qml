import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import com.jolla.lipstick 0.1
import org.nemomobile.lipstick 0.1
import "../main"

// Logically this is a focus scope with focus == active. It's not because a Layer is used for the
// grouped alarm on top of dialog on top of application peek through all of it to the homescreen
// peekLayer and other layers dynamically shift in an out of this layer and an layer whose window
// is given focus when the layer is outside of the peekLayer when it is introduced.
PixelAlignedItem {
    id: layer

    property Item window
    property alias transitionItem: peekArea.transitionItem
    property alias snapshotSource: peekArea.snapshotSource
    property alias underlayItem: peekArea.underlayItem
    property alias contentItem: peekArea.contentItem
    readonly property alias contentOpacity: peekArea.opacity
    property alias overlayItem: peekArea.overlayItem
    property bool active: window && Lipstick.compositor.topmostWindow === window
    property bool peekedAt
    property bool exposed: (window && window.parent == contentItem) && (Lipstick.compositor.topmostWindow === window
                            || Lipstick.compositor.exposedWindow === window
                            || layer.peekedAt
                            || layer._effectiveTransitioning
                            || active
                            || peekArea.closeAnimating)
    property alias windowVisible: peekArea.contentVisible
    property bool opaque: exposed
                && childrenOpaque
                && !peekArea.peeking
                && !_effectiveTransitioning
                && _smoothOpaque
                && !transitionIsPending
    property bool childrenOpaque: true
    property alias peekFilter: peekArea.peekFilter
    readonly property alias peeking: peekArea.peeking
    readonly property alias closing: peekArea.closing
    property alias quickAppToggleGestureExceeded: peekArea.quickAppToggleGestureExceeded
    property alias delayClose: peekArea.delayClose
    property bool _effectiveTransitioning
    property bool _smoothOpaque: true
    property bool transitioning: clip
    property bool transitionIsPending
    property bool peekingAtHome

    property Item background
    property bool renderBackground: window && window.renderBackground && window.mapped
    property bool renderDialogBackground: window && window.renderDialogBackground && window.mapped
    property bool mergeWindows: renderBackground || (window && window.hasChildWindows && window.mapped)
    readonly property bool renderSnapshot: exposed && mergeWindows && (transitioning || peeking || peekingAtHome)
    readonly property rect backgroundRect: window && window.backgroundRect !== undefined ? window.backgroundRect : Qt.rect(0, 0, width, height)
    readonly property bool opaqueAndMapped: opaque && window && (window.mapped === undefined || window.mapped)
    default property alias _data: peekArea._data

    property int __compositor_is_layer  // Identifies this as a layer to OverlayLayer.qml

    signal aboutToClose
    signal closed
    signal completeTransitions()

    onWindowChanged: Lipstick.compositor.updateWindows()

    onTransitioningChanged: {
        _smoothOpaque = opaque
        _effectiveTransitioning = transitioning
        _smoothOpaque = true
    }

    onCompleteTransitions: peekArea.completeTransitions()

    onActiveChanged: {
        if (Lipstick.compositor.debug) {
            console.log("Layer: \"", layer, "\" active: ", active)
            console.trace()
        }
    }

    anchors.fill: parent

    function close() {
        peekArea.close()
    }

    Connections {
        target: Lipstick.compositor
        onDisplayAboutToBeOff: layer.completeTransitions()
    }

    PeekArea {
        id: peekArea

        exposed: layer.exposed
        underlayItem.objectName: layer.objectName

        contentOpacity: layer.window ? layer.window.windowOpacity : 1.0

        onAboutToClose: layer.aboutToClose()
        onClosed: layer.closed()
    }
}
