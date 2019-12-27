import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Calendar 1.0

MenuItem {
    property int seconds: -1 // ReminderNone
    text: CommonCalendarTranslations.getReminderText(seconds)
}
