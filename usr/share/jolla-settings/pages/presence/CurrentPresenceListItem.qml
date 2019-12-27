import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import org.nemomobile.contacts 1.0

ListItem {
    id: root

    property int presenceState
    property int leftMargin: Theme.horizontalPageMargin
    property int rightMargin: Theme.horizontalPageMargin

    visible: PresenceListener.accounts.length > 0
    width: parent.width
    height: visible ? implicitHeight : 0

    Image {
        id: icon
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: root.leftMargin
        }
        width: Theme.iconSizeMedium
        source: "image://theme/icon-m-presence?" + (root.highlighted ? Theme.highlightColor : Theme.primaryColor)
    }

    Label {
        id: label

        anchors {
            verticalCenter: parent.verticalCenter
            left: icon.right
            leftMargin: Theme.paddingMedium
        }
        color: root.highlighted ? Theme.highlightColor : Theme.primaryColor
        //: Followed by presence state description
        //% "Presence"
        text: qsTrId("settings_presence-la-presence_leader")
    }

    Label {
        anchors {
            verticalCenter: parent.verticalCenter
            left: label.right
            leftMargin: Theme.paddingSmall
            right: parent.right
            rightMargin: root.rightMargin
        }
        truncationMode: TruncationMode.Fade
        color: Theme.highlightColor
        text: {
            if (presenceState === Person.PresenceUnknown) {
                //: Presence cannot be determined
                //% "Unavailable"
                return qsTrId("settings_presence-la-unavailable")
            }
            return PresenceListener.presenceStateText(presenceState)
        }
    }
}

