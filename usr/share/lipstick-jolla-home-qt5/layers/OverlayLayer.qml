import QtQuick 2.6
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1
import com.jolla.lipstick 0.1

Item {
    id: overlayLayer

    property alias contentItem: overlayLayer

    onChildrenChanged: updateWindows()
    z: 10000 // ensure on top of siblings after reparenting

    property Item activeFocusItem

    onActiveFocusItemChanged: {
        // Search for the layer of the focus item
        var focusedLayer = activeFocusItem
        while (focusedLayer && focusedLayer.__compositor_is_layer === undefined)
            focusedLayer = focusedLayer.parent

        // reparent the overlay to the found layer
        overlayLayer.parent = focusedLayer ? focusedLayer.overlayItem : overlayLayer.parent
        overlayLayer.visible = true
    }
}
