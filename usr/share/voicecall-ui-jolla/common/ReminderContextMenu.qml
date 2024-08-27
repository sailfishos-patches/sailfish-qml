import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.voicecall 1.0
import "."

ContextMenu {
    id: reminderMenu

    property string number
    property var person

    property bool showReminderOptions: true

    Repeater {
        // In minutes
        model: reminderMenu.showReminderOptions ? [ 30, 60, 2 * 60, 3 * 60  ] : []

        MenuItem {
            // formatDate() is relative to the current time, so the time is padded by a half a second
            // to allow for the time between Date.now() and formatDate() executing.
            text: Format.formatDate(
                      new Date(Date.now() + (modelData * 60 * 1000) + 500), Format.TimeElapsed)
            onClicked: {
                var name = reminderMenu.person
                        ? reminderMenu.person.displayLabel
                        : reminderMenu.number

                Reminders.create(reminderMenu.number, name, modelData)

                if (!reminderMenu.closeOnActivation) {
                    reminderMenu.close()
                }
            }
        }
    }
}
