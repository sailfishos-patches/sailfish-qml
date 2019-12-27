import QtQuick 2.0
import Sailfish.Silica 1.0

Column {
    property alias title: titleLabel.text
    property alias titleVisible: titleLabel.visible
    property alias text: subLabel.text

    anchors {
        left: parent ? parent.left : undefined
        right: parent ? parent.right : undefined
    }

    Label {
        id: titleLabel

        width: Math.min(parent.width, implicitWidth)
        x: (parent.width - width) / 2

        color: Theme.primaryColor
        font.pixelSize: Theme.fontSizeLarge
        truncationMode: TruncationMode.Fade
    }

    Label {
        id: subLabel

        width: Math.min(parent.width, implicitWidth)
        x: (parent.width - width) / 2

        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeExtraSmall
        truncationMode: TruncationMode.Fade
    }
}

