import QtQuick 2.0
import Sailfish.Silica 1.0
import "../compositor"
import org.nemomobile.lipstick 0.1

StackLayer {
    id: dialogLayer

    objectName: "dialogLayer"
    childrenOpaque: false

    onQueueWindow: contentItem.prependItem(window)

    underlayItem.children: [
        Rectangle {
            width: dialogLayer.width
            height: dialogLayer.height
            color: Theme.highlightDimmerColor
            visible: dialogLayer.renderDialogBackground
            opacity: Theme.opacityLow
        },

        BlurredBackground {
            visible: dialogLayer.renderDialogBackground
            x: dialogLayer.backgroundRect.x
            y: dialogLayer.backgroundRect.y
            width: dialogLayer.backgroundRect.width
            height: dialogLayer.backgroundRect.height
            backgroundItem: Lipstick.compositor.dialogBlurSource
        }
    ]
}
