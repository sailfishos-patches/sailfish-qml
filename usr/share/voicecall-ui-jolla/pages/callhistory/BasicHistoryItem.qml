import QtQuick 2.6
import Sailfish.Silica 1.0
import "../../common"

Item {
    id: root
    width: parent ? parent.width : Screen.width
    height: nameLabel.height

    CallDirectionIcon {
        id: icon

        x: Theme.paddingMedium
        call: historyItem.call
        anchors.verticalCenter: parent.verticalCenter
        hasReminder: reminder.exists
    }

    Row {
        x: leftMargin
        anchors.verticalCenter: parent.verticalCenter

        NameLabel {
            id: nameLabel
            width: root.width - parent.x - (timeStampLabel.visible ? timeStampLabel.width + parent.spacing : 0)
            anchors.verticalCenter: parent.verticalCenter
        }

        TimeStampLabel {
            id: timeStampLabel
            anchors.verticalCenter: parent.verticalCenter
            formatType: time.getFullYear() !== main.today.getFullYear() ? Format.DateMedium : Formatter.TimepointRelativeCurrentDay
        }
    }
}
