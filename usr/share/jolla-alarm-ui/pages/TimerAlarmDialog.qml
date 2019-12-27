import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.alarmui 1.0

AlarmDialogBase {
    onTimeout: closeDialog(AlarmDialogStatus.Dismissed)

    Label {
        anchors { left: parent.left; right: parent.right }
        color: Theme.primaryColor
        font {
            pixelSize: Theme.fontSizeHuge
            family: Theme.fontFamilyHeading
        }
        horizontalAlignment: Text.AlignHCenter
        maximumLineCount: 4
        text: alarm.title
        wrapMode: Text.Wrap
    }

    Label {
        function timeText(label, value) {
            return value.toLocaleString() + "\u00A0<font size=\'2'>" + label + "</font>"
        }

        wrapMode: Text.Wrap
        textFormat: Text.RichText
        font.pixelSize: Theme.fontSizeLarge
        horizontalAlignment: Text.AlignHCenter
        width: parent.width - 2 * Theme.horizontalPageMargin
        anchors.horizontalCenter: parent.horizontalCenter
        text: {
            //: "text part of '3 hour(s)'"
            //% "hour(s)"
            var hourText = timeText(qsTrId("alarm-la-hours", alarm.hour), alarm.hour)

            //: "text part of '3 minute(s)'"
            //% "minute(s)"
            var minuteText = timeText(qsTrId("alarm-la-minutes", alarm.minute), alarm.minute)

            //: "text part of '3 second(s)'"
            //% "second(s)"
            var secondText = timeText(qsTrId("alarm-la-seconds", alarm.second), alarm.second)

            if (alarm.hour !== 0 && alarm.minute !== 0) {
                //: Order of "2 hours 1 minute", when composed of strings "2 hours" and "1 minute"
                //% "%1 %2"
                return qsTrId("alarm-la-hours_and_minutes").arg(hourText).arg(minuteText)
            } else if (alarm.minute !== 0 && alarm.second !== 0) {
                //: Order of "1 minute 12 seconds", when composed of strings "1 minute" and "12 seconds"
                //% "%1 %2"
                return qsTrId("alarm-la-minutes_and_seconds").arg(minuteText).arg(secondText)
            } else if (alarm.hour !== 0) {
                return hourText
            } else if (alarm.minute !== 0) {
                return minuteText
            } else if (alarm.second !== 0) {
                return secondText
            } else {
                return ""
            }
        }
    }
}
