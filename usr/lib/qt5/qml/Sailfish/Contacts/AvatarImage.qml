import QtQuick 2.0
import Sailfish.Silica 1.0

Image {
    readonly property bool available: status === Image.Ready
    property int itemSize: Math.round(Screen.width / 3)

    width: itemSize
    height: itemSize
    sourceSize.width: width
    sourceSize.height: height
    fillMode: Image.PreserveAspectCrop
    cache: false
    clip: true
}
