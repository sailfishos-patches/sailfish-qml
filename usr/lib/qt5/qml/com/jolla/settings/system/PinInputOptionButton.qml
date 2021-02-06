import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: root

    property string text
    property color primaryColor: Theme.primaryColor
    property bool emergency
    property bool showWhiteBackgroundByDefault
    property alias icon: icon

    visible: text !== ""
    contentItem.radius: 4
    highlighted: showWhiteBackgroundByDefault || down

    highlightedColor: {
        if (emergency) {
            if (root.showWhiteBackgroundByDefault && !down) {
                return "white"
            }

            return emergencyTextColor
        }
        return Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
    }

    Icon {
        id: icon

        visible: false
        highlighted: root.highlighted
        color: root.primaryColor
        anchors {
            centerIn: parent
            verticalCenterOffset: -Theme.fontSizeExtraSmall / 3
        }
    }

    Label {
        x: Math.round((root.width - width) / 2)
        y: root.height - baselineOffset - Theme.paddingLarge
        width: Math.min(implicitWidth, parent.width - 2*Theme.paddingSmall)
        text: root.text
        font.pixelSize: Theme.fontSizeMedium
        font.bold: root.emergency
        fontSizeMode: Text.HorizontalFit
        visible: !icon.visible

        color: {
            if (root.emergency) {
                if (showWhiteBackgroundByDefault) {
                    return "black"
                }
                return root.highlighted ? "black" : "white"
            }
            return root.highlighted ? Theme.highlightColor : root.primaryColor
        }
    }
}
