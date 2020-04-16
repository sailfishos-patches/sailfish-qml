import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import Sailfish.Telephony 1.0
import "../../common"

Column {
    id: root

    readonly property var _simManager: simManager

    width: parent ? parent.width : Screen.width

    Item {
        width: parent.width
        height: companyLabel.y + companyLabel.height

        CallDirectionIcon {
            id: icon

            x: Theme.paddingMedium
            call: historyItem.call
            anchors.verticalCenter: nameLabel.verticalCenter
        }

        NameLabel {
            id: nameLabel

            x: leftMargin
            width: parent.width - x
            secondaryLabel.color: secondaryLabel.highlighted ? palette.highlightColor : palette.primaryColor
        }

        Label {
            id: companyLabel

            anchors {
                left: nameLabel.left
                right: nameLabel.right
                top: nameLabel.bottom
            }
            visible: text !== numberTypeLabel.text
            height: visible && text.length > 0 ? implicitHeight : 0
            truncationMode: TruncationMode.Fade

            text: person ? person.companyName : ""
            font.pixelSize: Theme.fontSizeSmall
            color: highlighted ? palette.secondaryHighlightColor : palette.secondaryColor
        }
    }

    Row {
        width: parent.width - x
        spacing: Theme.paddingSmall
        x: leftMargin

        Label {
            id: numberTypeLabel

            text: numberDetail !== defaultNumberDetail || companyLabel.text.length === 0
                  ? numberDetail
                  : companyLabel.text
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
        height: Math.max(callDurationItem.height, simIndicator.height, dateLabel.height)
        x: leftMargin

        CallDurationItem {
            id: callDurationItem

            anchors.verticalCenter: parent.verticalCenter
        }

        ContactActivitySimIndicator {
            id: simIndicator

            x: callDurationItem.x + callDurationItem.width + Theme.paddingSmall
            anchors.verticalCenter: parent.verticalCenter
            maximumWidth: reminderIcon.x - Theme.paddingSmall - x

            visible: simManager.simCount > 1
            simManager: _simManager
            imsi: subscriberIdentity
            showSimOperator: Telephony.voiceSimUsageMode === Telephony.AlwaysAskSim
                             && (simManager.simNames.length > 1 && simManager.simNames[0] !== simManager.simNames[1])
        }

        HighlightImage {
            id: reminderIcon

            readonly property real elidedX: dateLabel.x - reminderLabel.width - width - (2 * Theme.paddingSmall)
            readonly property real unelidedX: simIndicator.x + (simIndicator.visible ? simIndicator.implicitWidth : 0) + Theme.paddingSmall

            x: visible && unelidedX < elidedX ? unelidedX : elidedX
            anchors.verticalCenter: parent.verticalCenter

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
