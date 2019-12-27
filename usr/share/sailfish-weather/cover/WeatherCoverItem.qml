import QtQuick 2.0
import Sailfish.Silica 1.0

Column {    
    property alias text: primaryLabel.text
    property alias description: secondaryLabel.text
    property alias topPadding: topPaddingItem.height

    Item {
        id: topPaddingItem
        width: parent.width
    }
    Label {
        id: primaryLabel
        width: parent.width
        truncationMode: TruncationMode.Fade
    }
    Label {
        id: secondaryLabel
        width: parent.width
        truncationMode: TruncationMode.Fade
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryColor
    }
}
