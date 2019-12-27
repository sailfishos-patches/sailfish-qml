import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    Image {
        id: background

        anchors.fill: parent
        source: "image://theme/graphic-cover-archive"
    }

    OpacityRampEffect {
        sourceItem: background
        slope: 0.5
        offset: 0.2
        direction: OpacityRamp.TopToBottom
    }

    Label {
        anchors { bottom: parent.bottom; bottomMargin: Theme.paddingLarge }
        x: Theme.paddingLarge
        width: parent.width - Theme.paddingLarge*2
        color: Theme.primaryColor
        truncationMode: TruncationMode.Fade
        fontSizeMode: Text.HorizontalFit
        font.pixelSize: Theme.fontSizeLarge
        horizontalAlignment: Text.AlignHCenter
        text: coverText
    }
}

