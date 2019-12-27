import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import org.nemomobile.lipstick 0.1
import "../main"

PannableItem {
    id: layer

    property Item window

    property bool active: window && Lipstick.compositor.topmostWindow === window
    property bool opaque

    property bool maximized

    property real statusOffset: 0
    property real statusOpacity: 1.0

    property real minimizeMargin

    property int __compositor_is_layer  // Identifies this as a layer to OverlayLayer.qml

    onWindowChanged: Lipstick.compositor.updateWindows()
}
