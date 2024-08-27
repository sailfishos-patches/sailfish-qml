import QtQuick 2.0
import Sailfish.Silica 1.0

MediaContainerListDelegate {
    id: root

    property string iconSource
    property alias iconSourceSize: mediaContainerIcon.sourceSize

    leftPadding: Theme.itemSizeExtraLarge + Theme.paddingLarge

    Image {
        id: mediaContainerIcon
        x: Theme.itemSizeExtraLarge - width
        source: root.iconSource + (root.highlighted && root.iconSource !== "" ? ("?" + Theme.highlightColor)
                                                                              : "")
        anchors.verticalCenter: parent.verticalCenter
    }
}
