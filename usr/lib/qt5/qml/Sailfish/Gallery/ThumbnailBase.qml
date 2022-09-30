import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Gallery 1.0

GridItem {
    id: thumbnail

    property url source
    property string mimeType: model && model.mimeType ? model.mimeType : ""
    property int size: GridView.view.cellSize
    property bool selected

    width: size
    contentHeight: size
    opacity: down && selected && !menuOpen ? 0.8 : 1.0
    highlighted: down || menuOpen || selected

    HighlightItem {
        z: 1
        active: thumbnail.highlighted && !thumbnail.menuOpen
        anchors.fill: parent
    }
}
