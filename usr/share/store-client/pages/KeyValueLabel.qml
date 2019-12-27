import QtQuick 2.0
import Sailfish.Silica 1.0

/* Fancy label for key-value pairs.
 */
Label {
    property string key
    property string value
    property color keyColor: Theme.secondaryHighlightColor

    width: parent.width
    color: Theme.highlightColor
    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
    font.pixelSize: Theme.fontSizeExtraSmall
    textFormat: Text.StyledText
    text: "<font color=\"" + keyColor + "\">" +
          key + "</font> " + value.replace(/\n/g, '<br>')
}
