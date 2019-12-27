import QtQuick 2.6
import Sailfish.Silica 1.0
import "../../common"

Column {
    readonly property int modemIndex: simManager.simNames ? simManager.indexOfModemFromImsi(subscriberIdentity)
                                                          : -1
    width: parent ? parent.width : Screen.width

    Item {
        width: parent.width
        height: nameLabel.height

        CallDirectionIcon {
            id: icon

            x: Theme.paddingMedium
            call: historyItem.call
            anchors.verticalCenter: parent.verticalCenter
        }

        NameLabel {
            id: nameLabel

            x: leftMargin
            width: parent.width - x
            anchors.verticalCenter: parent.verticalCenter
            secondaryLabel.color: secondaryLabel.highlighted ? palette.highlightColor : palette.primaryColor
        }
    }

    Row {
        width: parent.width - x
        spacing: Theme.paddingSmall
        x: leftMargin

        Label {
            text: numberDetail
            width: parent.width - (timeLabel.visible ? timeLabel.width + parent.spacing : 0)
            truncationMode: TruncationMode.Fade
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: Theme.fontSizeSmall
            color: highlighted ? palette.secondaryHighlightColor : palette.secondaryColor
        }

        TimeStampLabel {
            id: timeLabel
            anchors.verticalCenter: parent.verticalCenter
            formatType: Formatter.TimeValue
        }
    }

    Item {
        width: parent.width - x
        height: Theme.iconSizeSmall
        x: leftMargin

        CallDurationItem {
            id: callDurationItem
            height: parent.height
        }

        HighlightImage {
            id: simIcon

            x: callDurationItem.x + callDurationItem.width + Theme.paddingSmall
            color: palette.secondaryColor
            highlightColor: palette.secondaryHighlightColor
            visible: status === Image.Ready
            anchors.verticalCenter: parent.verticalCenter
            source: {
                if (!multipleSimCards) return ""
                switch (modemIndex) {
                    case 0: return "image://theme/icon-s-sim-1"
                    case 1: return "image://theme/icon-s-sim-2"
                    default: return ""
                }
            }
        }

        Label {
            id: simLabel

            x: simIcon.x + simIcon.width + Theme.paddingSmall

            text: modemIndex >= 0 ? simManager.modemSimModel.get(modemIndex).operatorDescription : ""
            truncationMode: TruncationMode.Fade
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: Theme.fontSizeSmall
            opacity: simIcon.visible ? 1 : 0
            color: highlighted ? palette.secondaryHighlightColor : palette.secondaryColor
            width: reminderIcon.x - Theme.paddingSmall - x
        }

        HighlightImage {
            id: reminderIcon

            readonly property real elidedX: dateLabel.x - reminderLabel.width - width - (2 * Theme.paddingSmall)
            readonly property real unelidedX: simLabel.x + simLabel.implicitWidth + Theme.paddingSmall

            x: visible && unelidedX < elidedX ? unelidedX : elidedX

            source: "image://theme/icon-s-alarm"
            visible: reminder.exists
        }

        Label {
            id: reminderLabel

            x: reminderIcon.x + reminderIcon.width + Theme.paddingSmall

            color: highlighted ? palette.secondaryHighlightColor : palette.secondaryColor
            font.pixelSize: Theme.fontSizeSmall
            anchors.verticalCenter: parent.verticalCenter
            text: reminder.exists ? Format.formatDate(reminder.when, Formatter.TimeValue) : ""
        }

        TimeStampLabel {
            id: dateLabel

            x: parent.width - width

            font.pixelSize: Theme.fontSizeSmall
            formatType: time.getFullYear() !== main.today.getFullYear() ? Format.DateMedium : Format.DateMediumWithoutYear
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
