import QtQuick 2.1
import Sailfish.Silica 1.0

Item {
    height: image.height

    Image {
        id: image

        x: Theme.horizontalPageMargin
        width: Theme.itemSizeSmall
        height: width
        source: "graphic-brand-icasa.png"

        Text {
            anchors.left: parent.right
            anchors.leftMargin: Theme.paddingMedium
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeTiny
            text: "TA-2013/2346\nAPPROVED"
        }
    }
}
