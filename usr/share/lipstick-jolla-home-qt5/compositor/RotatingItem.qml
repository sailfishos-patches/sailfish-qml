import QtQuick 2.2
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1

Item {
    id: rotatingItem

    readonly property real transposed: rotation % 180 != 0
    readonly property bool inverted: rotation == 180 || rotation == 270

    anchors.centerIn: parent
    rotation: Lipstick.compositor.topmostWindowAngle
    Behavior on rotation {
        SequentialAnimation {
            FadeAnimation { target: rotatingItem; to: 0.0 }
            PropertyAction { property: "rotation" }
            FadeAnimation { target: rotatingItem; to: 1.0 }
        }
    }

    width: transposed
            ? Lipstick.compositor.height
            : Lipstick.compositor.width
    height: transposed
            ? Lipstick.compositor.width
            : Lipstick.compositor.height
}
