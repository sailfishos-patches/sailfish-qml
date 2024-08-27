import QtQuick 2.0
import Sailfish.Silica 1.0

Rectangle {
    id: fieldItem

    property bool coverMode
    property bool fractionBar
    property bool focused
    property alias linkText: linkLabel.text
    property alias numerator: numeratorLabel.text
    property alias denominator: denominatorLabel.text
    property bool highlighted: focused || mouseArea.down

    signal clicked

    // cover content is tight, need negative padding to avoid overlap
    height: content.height + 2 * (coverMode ? (fractionBar ? -0.2*Theme.paddingSmall : 0.3*Theme.paddingLarge)
                                            : (fractionBar ? Theme.paddingSmall : Theme.paddingLarge))
    // square size until expanded with content
    width: Math.max((numeratorLabel.height + 2 * (coverMode ? 0.3*Theme.paddingLarge : Theme.paddingLarge)),
                    Math.max(numeratorLabel.width, denominatorLabel.width) + 2*(coverMode ? Theme.paddingMedium
                                                                                          : Theme.paddingLarge))

    color: Theme.rgba(highlighted ? Theme.highlightColor : Theme.primaryColor,
                      highlighted ? Theme.highlightBackgroundOpacity : 0.1)
    MouseArea {
        id: mouseArea

        property bool down: pressed && containsMouse

        anchors.fill: parent
        onClicked: fieldItem.clicked()
    }

    Column {
        id: content

        width: parent.width
        anchors.verticalCenter: parent.verticalCenter
        Label {
            id: numeratorLabel
            color: mouseArea.down ? Theme.highlightColor : Theme.primaryColor
            font.pixelSize: primaryFontSize
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Rectangle {
            height: Math.round(Theme.paddingSmall/3)
            visible: fractionBar
            color: Theme.highlightColor
            anchors {
                left: parent.left
                right: parent.right
                margins: (coverMode ? 0.5 : 1.0) * Theme.paddingMedium
            }
        }
        Label {
            id: denominatorLabel
            visible: fractionBar
            color: mouseArea.down ? Theme.highlightColor : Theme.primaryColor
            font.pixelSize: primaryFontSize
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
    LinkLabel {
        id: linkLabel
        coverMode: parent.coverMode
    }
}
