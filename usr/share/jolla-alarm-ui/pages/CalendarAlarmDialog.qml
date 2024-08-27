import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.alarmui 1.0
import Nemo.DBus 2.0

AlarmDialogBase {
    id: root

    property bool endValid: !isNaN(alarm.endDate.getTime())
    property bool singleDay: !endValid
                             || daysEqual(alarm.startDate, alarm.endDate)
    property date now: new Date()
    property int dbusRequestCounter
    property bool waitingForDBusResponse: dbusRequestCounter > 0

    topIconSource: "image://theme/icon-l-date?" + Theme.highlightColor
    onTimeout: closeDialog(AlarmDialogStatus.Closed)
    pushUpAnimationHint: false

    function dbusRequestComplete() {
        if (dbusRequestCounter > 0) {
            dbusRequestCounter--
        }
    }

    function daysEqual(day1, day2) {
        return day1.getFullYear() === day2.getFullYear()
                && day1.getMonth() === day2.getMonth()
                && day1.getDate() === day2.getDate()
    }

    PullDownMenu {
        bottomMargin: Theme.itemSizeExtraSmall
        MenuItem {
            //% "Snooze"
            text: qsTrId("alarm-ui-me-alarm_dialog_snooze")
            onClicked: closeDialog(AlarmDialogStatus.Snoozed)
        }
        MenuItem {
            //% "Show event"
            text: qsTrId("alarm-ui-me-alarm_dialog_showEvent")
            onClicked: {
                mce.call("req_tklock_mode_change", "unlocked")
                closeDialog(AlarmDialogStatus.Dismissed)
                var ok = calendar.typedCall("viewEvent",
                                            [
                                                { "type":"s", "value": alarm.notebookUid },
                                                { "type":"s", "value": alarm.calendarEventUid },
                                                { "type":"s", "value": alarm.calendarEventRecurrenceId },
                                                { "type":"s", "value": Qt.formatDateTime(alarm.startDate, Qt.ISODate) }
                                            ],
                                            dbusRequestComplete,
                                            dbusRequestComplete);
                if (ok) {
                    dbusRequestCounter++
                }
            }

        }
    }

    Label {
        anchors {
            left: parent.left; right: parent.right
        }
        color: Theme.primaryColor
        font {
            pixelSize: Theme.fontSizeHuge
            family: Theme.fontFamilyHeading
        }
        horizontalAlignment: Text.AlignHCenter
        maximumLineCount: 4
        //: Fallback text on calendar alarm for events without a title
        //% "(Unnamed event)"
        text: alarm.title.trim() != "" ? alarm.title : qsTrId("jolla-alarm-la-untitled_calendar_event")
        wrapMode: Text.Wrap
    }

    Label {
        property bool afterTomorrow: {
            var dayAfterTomorrow = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 2)
            return alarm.startDate.getTime() >= dayAfterTomorrow.getTime()
        }

        visible: {
            var tomorrow = new Date()
            tomorrow.setDate(tomorrow.getDate() + 1)
            return root.singleDay || daysEqual(alarm.startDate, now) || daysEqual(alarm.startDate, tomorrow)
        }
        anchors {
            left: parent.left; right: parent.right
        }
        font {
            pixelSize: afterTomorrow ? Theme.fontSizeMedium : Theme.fontSizeLarge
        }
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: {
            if (afterTomorrow) {
                // TODO: year could be omitted
                return Format.formatDate(alarm.startDate, Formatter.DateFull)
            }

            // assuming we don't need to track when minute changes and update text
            if (now.getTime() >= alarm.startDate.getTime()) {
                //% "Now"
                return qsTrId("alarm-ui-la-now")
            }
            var minuteDiff = Math.round((alarm.startDate.getTime() - now.getTime()) / (1000 * 60))

            if (minuteDiff <= 6*60 || daysEqual(alarm.startDate, now)) {
                var hours = Math.floor(minuteDiff / 60)
                var minutes = Math.round(minuteDiff % 60)

                if (hours == 0) {
                    //% "In %n minutes"
                    return qsTrId("alarm-ui-minutes_to_event", minutes)
                } else if (minutes == 0) {
                    //% "In %n hours"
                    return qsTrId("alarm-ui-hours_to_event", hours)
                } else {
                    //% "%n hours"
                    var hourPart = qsTrId("alarm-ui-hour_part_to_event", hours)
                    //% "%n minutes"
                    var minutePart = qsTrId("alarm-ui-minute_part_to_event", minutes)

                    //: N hours and N minutes to alarm, %1 is replaced with hour_part_to_event,
                    //: %2 with minute_part_to_event
                    //% "In %1 %2"
                    return qsTrId("alarm-ui-la-pattern_hours_and_minutes_to_event").arg(hourPart).arg(minutePart)
                }
            } else {
                //% "Tomorrow"
                return qsTrId("alarm-ui-la-tomorrow")
            }
        }
    }

    Label {
        property string startTime: Format.formatDate(alarm.startDate, Formatter.TimeValue)
        property string endTime: Format.formatDate(alarm.endDate, Formatter.TimeValue)

        visible: root.singleDay
        anchors {
            left: parent.left; right: parent.right
        }
        font {
            pixelSize: Theme.fontSizeExtraLarge
            family: Theme.fontFamilyHeading
        }

        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        //% "All day"
        text: alarm.allDay ? qsTrId("alarm-ui-la-all_day")
                             //: Pattern for calendar event time %1 is start time, %2 is end time
                             //% "%1-%2"
                           : root.endValid
                             ? qsTrId("alarm-ui-me-alarm_dialog_start_time_end_time").arg(startTime).arg(endTime)
                             : startTime
    }

    Label {
        anchors {
            left: parent.left; right: parent.right
        }
        font.pixelSize: Theme.fontSizeMedium
        horizontalAlignment: Text.AlignHCenter
        visible: !root.singleDay
        wrapMode: Text.Wrap
        text: {
            // TODO: years could be omitted
            var startDate = Format.formatDate(alarm.startDate, alarm.allDay ? Formatter.DateFull : Formatter.DateLong)
            var endDate = Format.formatDate(alarm.endDate, alarm.allDay ? Formatter.DateFull : Formatter.DateLong)

            if (alarm.allDay) {
                //: Pattern for displaying start and end date on a calendar reminder (days not equal)
                //: %1 replaced with start date string, %2 with end. \n can be used for new line
                //% "%1 -\n%2"
                return qsTrId("alarm-ui-la-multi_day_all_day_pattern").arg(startDate).arg(endDate)
                    .replace(/\\n/g, "\n")
            } else {
                var startTime = Format.formatDate(alarm.startDate, Formatter.TimeValue)
                var endTime = Format.formatDate(alarm.endDate, Formatter.TimeValue)
                //: Pattern for displaying date and time for event start and end
                //: %1 = start date, %2 = start time, %3 = end date, %4 = end time, \n can be used for new line
                //% "%1\n%2 -\n%3\n%4"
                return qsTrId("alarm-ui-la-multi_day_pattern").arg(startDate).arg(startTime).arg(endDate).arg(endTime)
                    .replace(/\\n/g, "\n")
            }
        }
    }

    data: [
        DBusInterface {
            id: calendar

            service: "com.jolla.calendar.ui"
            path: "/com/jolla/calendar/ui"
            iface: "com.jolla.calendar.ui"
        },
        DBusInterface {
            id: mce

            service: "com.nokia.mce"
            path: "/com/nokia/mce/request"
            iface: "com.nokia.mce.request"
            bus: DBus.SystemBus
        }
    ]
}
