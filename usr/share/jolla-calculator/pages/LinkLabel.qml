import QtQuick 2.0
import Sailfish.Silica 1.0

Label {
    property bool coverMode
    font {
        weight: Font.Bold
        pixelSize: coverMode ? Theme.fontSizeTiny : Theme.fontSizeExtraSmall
    }
    anchors {
        top: parent.top
        right: parent.left
        topMargin: -Theme.paddingSmall
        rightMargin: Theme.paddingSmall
    }
}
