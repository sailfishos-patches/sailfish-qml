pragma Singleton

import QtQml 2.2
import Sailfish.Silica 1.0
import com.jolla.voicecall 1.0

RemindersBase {
    function create(number, name, minutes) {
        var when = new Date(Date.now() + (minutes * 60 * 1000))

        //% "Call Reminder"
        var applicationName = qsTrId("voicecall-he-call_reminders")

        var contactName = name.length > 0 ? name : number

        //: Return a call from the contact or phone number %1
        //% "Call back %1"
        var title = qsTrId("voicecall-he-reminders-call_back").arg(contactName)

        //: The call reminder is for the time %1
        //% "Reminder at %1"
        var description = qsTrId("voicecall-la-call_reminder_at").arg(Format.formatDate(when, Formatter.TimeValue))

        createWithStrings(number, when, applicationName, contactName, title, description)
    }
}
