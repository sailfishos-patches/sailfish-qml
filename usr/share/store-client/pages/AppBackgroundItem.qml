import QtQuick 2.0
import Sailfish.Silica 1.0

/* Common background item for application items in grid type of views.
 */
BackgroundItem {
    property alias gradientOpacity: gradientImage.opacity

    Image {
        id: gradientImage

        anchors {
            bottom: parent.bottom
            right: parent.right
        }

        width: Math.min(parent.width, sourceSize.width)
        height: Math.min(parent.height, sourceSize.height)

        opacity: 0.15
        source: "image://theme/graphic-gradient-corner?" + Theme.highlightBackgroundColor
    }
}
