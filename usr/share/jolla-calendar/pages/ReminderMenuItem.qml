import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Calendar 1.0

MenuItem {
    property int seconds: -1 // ReminderNone
    property var date // When defined, assume reminder should be applied in reference to
    text: CalendarTexts.getReminderText(seconds, date)
}
