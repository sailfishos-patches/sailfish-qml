import QtQuick 2.5
import Sailfish.Silica 1.0

GridItem {
    id: noteitem

    property int pageNumber
    property color color
    property alias text: summary.text

    // Create a tint with 10% of the primaryColor in the lower left,
    // down to 0% in the upper right.
    // Is there any way to use OpacityRampEffect instead of Gradient here?
    Item {
        // The rectangle inside is rotated to rotate the gradient,
        // but then it needs to be clipped back to an upright square.
        // This container item does the clipping so that the NoteItem itself
        // doesn't have to clip (which would interfere with context menus)
        anchors.fill: parent
        clip: true
        Rectangle {
            rotation: 45 // diagonal gradient
            // Use square root of 2, rounded up a little bit, to make the
            // rotated square cover all of the parent square
            width: parent.width * 1.412136
            height: parent.height * 1.412136
            x: parent.width - width
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.rgba(Theme.primaryColor, 0) }
                GradientStop { position: 1.0; color: Theme.rgba(Theme.primaryColor, Theme.opacityFaint) }
            }
        }
    }

    Item {
        anchors { fill: parent; margins: Theme.paddingLarge }
        Text {
            id: summary
            anchors {
                top: parent.top
                topMargin: - (font.pixelSize / 4)
                left: parent.left
                right: parent.right
            }
            height: parent.height
            textFormat: Text.StyledText
            font { family: Theme.fontFamily; pixelSize: Theme.fontSizeSmall }
            color: highlighted ? Theme.highlightColor : Theme.primaryColor
            wrapMode: Text.Wrap
            maximumLineCount: Math.floor((height - Theme.paddingLarge) / fontMetrics.height)
            elide: Text.ElideRight
        }
        FontMetrics {
            id: fontMetrics
            font: summary.font
        }

        OpacityRampEffect {
            sourceItem: summary
            slope: 0.6
            offset: 0
            direction: OpacityRamp.TopToBottom
        }

        Rectangle {
            id: colortag
            property string testName: "colortag"

            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: Theme.itemSizeExtraSmall
            height: width/8
            radius: Math.round(Theme.paddingSmall/3)
            color: noteitem.color
        }
    }

    Text {
        id: pagenumber

        anchors.baseline: parent.bottom
        anchors.baselineOffset: -Theme.paddingMedium
        anchors.right: parent.right
        anchors.rightMargin: Theme.paddingMedium
        opacity: Theme.opacityLow
        color: highlighted ? Theme.highlightColor : Theme.primaryColor
        font { family: Theme.fontFamily; pixelSize: Theme.fontSizeLarge }
        horizontalAlignment: Text.AlignRight
        text: noteitem.pageNumber
    }
}
