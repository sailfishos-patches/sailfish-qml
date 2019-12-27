import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.commhistory 1.0
import "CallHistory.js" as CallHistory

Item {
    id: root

    property var call
    property bool hasReminder

    // less than 24 hours old (24*60*60*1000)
    property bool occurredToday: call && call.isMissedCall ? main.today - 86400000 < call.startTime.getTime() : false

    width: callDirectionIcon.width
    height: callDirectionIcon.height

    function color() {
        if (!occurredToday || hasReminder) {
            return undefined
        } else if (palette.colorScheme === Theme.LightOnDark) {
            return "#fc8272"
        } else {
            return "#991200"
        }
    }

    Icon {
        id: icon

        anchors {
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: countLabel.text.length > 0 ? Math.round(Theme.paddingSmall * 0.66) : 0
        }

        palette.primaryColor: root.color()
        source: {
            if (hasReminder) {
                return "image://theme/icon-s-alarm"
            } else if (!call) {
                return ""
            } else if (call.isMissedCall) {
                return "image://theme/icon-s-missed-call"
            } else if (call.direction === CommCallModel.Outbound) {
                return "image://theme/icon-s-outgoing-call"
            } else {
                return "image://theme/icon-s-incoming-call"
            }
        }
    }

    Label {
        id: countLabel

        // there's only space reserved for one character, so many missed calls will overlap text and icon a bit
        anchors {
            left: icon.right
            leftMargin: text.length > 1 ? -Theme.paddingSmall : 0
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: -Math.round(Theme.paddingSmall * 0.66)
        }

        palette.primaryColor: root.color()
        text: !hasReminder && call && call.isMissedCall && call.eventCount > 1
              ? (call.eventCount < 10 ? call.eventCount : "+9") : ""
        font { pixelSize: Theme.fontSizeTiny; weight: Font.Bold }
    }
}
