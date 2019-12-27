import QtQuick 2.0
import Sailfish.Silica 1.0

Column {
    id: root
    width: parent.width
    spacing: Theme.paddingLarge

    property alias explanationText: placeholder.text
    property alias actionText: action.text
    signal actionClicked()

    Item {
        width: parent.width
        height: Theme.paddingLarge
    }

    Label {
        id: placeholder

        anchors {
            left: parent.left
            right: parent.right
            margins: Theme.horizontalPageMargin
        }
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        font {
            pixelSize: Theme.fontSizeLarge
            family: Theme.fontFamilyHeading
        }
        color: Theme.secondaryHighlightColor
    }

    Label {
        id: action

        visible: text.length > 0
        font.pixelSize: Theme.fontSizeLarge
        anchors.horizontalCenter: parent.horizontalCenter
        color: enableMouseArea.pressed && enableMouseArea.containsMouse ? Theme.highlightColor
                                                                        : Theme.primaryColor
        MouseArea {
            id: enableMouseArea
            anchors.fill: parent
            onClicked: root.actionClicked()
        }
    }

    Item {
        width: parent.width
        height: 2*Theme.paddingLarge
    }
}
