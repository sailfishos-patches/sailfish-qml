import QtQuick 2.0
import Sailfish.Silica 1.0

Label {
    width: parent.width - x * 2
    x: Theme.horizontalPageMargin
    color: Theme.secondaryHighlightColor
    font.pixelSize: Theme.fontSizeSmall
    wrapMode: Text.Wrap
}
