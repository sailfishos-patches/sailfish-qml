import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1
import com.jolla.lipstick 0.1

Item {
    id: overlayLayer

    property alias contentItem: overlayLayer

    onChildrenChanged: updateWindows()

    readonly property Item activeFocusItem: root.activeFocusItem
                // There's no notification for item flags, but the only known instances of
                // ItemAcceptsInputMethod changing dynamically is the TextInput/Edit read only
                // property. By including it in the binding we'll force a re-evaluation if
                // the property both exists and changes.
                && !root.activeFocusItem.readOnly
                && JollaSystemInfo.itemAcceptsInputMethod(root.activeFocusItem)
            ? root.activeFocusItem
            : null

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
