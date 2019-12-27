import QtQuick 2.0

Image {
    source: "graphic-keyboard-highlight-top.png"
    anchors.right: parent.right
    // should scale based on pixel density
    width: geometry.scaleRatio >= 2 ? 2 : 1
    height: parent.height
    fillMode: Image.TileHorizontally
}
