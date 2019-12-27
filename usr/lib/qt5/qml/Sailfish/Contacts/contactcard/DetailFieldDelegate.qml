import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root

    property bool highlighted
    property alias value: contactDetailValue.text
    property alias metadata: contactDetailMetadata.text
    property alias metadataLabel: contactDetailMetadata

    visible: value.length > 0
    width: parent.width
    height: contactDetailMetadata.y + contactDetailMetadata.height

    Label {
        id: contactDetailValue
        width: parent.width
        color: root.highlighted ? Theme.highlightColor : Theme.primaryColor
        font.pixelSize: Theme.fontSizeMedium
        wrapMode: Text.Wrap
    }

    Label {
        id: contactDetailMetadata

        y: contactDetailValue.height
        width: parent.width
        color: root.highlighted ? Theme.highlightColor : Theme.secondaryColor
        font.pixelSize: Theme.fontSizeExtraSmall
        truncationMode: TruncationMode.Fade
        visible: text.length > 0
    }
}
