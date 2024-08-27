import QtQuick 2.6
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0

ListItem {
    id: root

    property bool required
    property string name
    property string email

    signal removed()
    signal moved()

    menu: attendeeMenuComponent
    contentHeight: Math.max(labels.height, removeButton.height) + 2*Theme.paddingSmall

    Column {
        id: labels
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
            right: removeButton.left
            rightMargin: Theme.paddingMedium
        }
        Label {
            text: name.length > 0 ? name : email
            truncationMode: TruncationMode.Fade
            width: parent.width
            font.pixelSize: Theme.fontSizeMedium
            color: root.highlighted ? Theme.highlightColor : Theme.primaryColor
        }
        Label {
            text: (name.length > 0 && name != email) ? email : ""
            truncationMode: TruncationMode.Fade
            width: parent.width
            font.pixelSize: Theme.fontSizeTiny
            color: root.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            visible: text != ""
        }
    }

    IconButton {
        id: removeButton
        anchors.right: parent.right
        anchors.rightMargin: Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter
        icon.source: "image://theme/icon-m-clear"
        highlighted: root.highlighted || down
        onClicked: root.removed()
    }

    Component {
        id: attendeeMenuComponent
        ContextMenu {
            MenuItem {
                text: root.required ? //% "Move to optional"
                                      qsTrId("calendar-move_to_optional")
                                    : //% "Move to invited"
                                      qsTrId("calendar-move_to_invited")
                onClicked: root.moved()
            }
        }
    }
}
