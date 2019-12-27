import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.TextLinking 1.0

/* Fancy label for key-value pairs with text linking support.
 */

Text {
    // Cannot use LinkedText directly because the html used for
    // formatting would be escaped. -> Using LinkParser and
    // LinkHandler directly.
    property string key
    property alias value: linkParser.text
    property color keyColor: Theme.secondaryHighlightColor

    width: parent.width
    color: Theme.highlightColor
    linkColor: Theme.highlightColor
    textFormat: Text.StyledText
    wrapMode: Text.Wrap
    font.pixelSize: Theme.fontSizeExtraSmall
    text: "<font color=\"" + keyColor + "\">" +
          key + "</font> " + linkParser.linkedText.replace(/\n/g, '<br>')

    onLinkActivated: {
        handler.handleLink(link)
    }

    LinkHandler {
        id: handler
    }

    LinkParser {
        id: linkParser
    }
}
