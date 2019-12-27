import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

Column {
    id: root

    property alias profileId: calendarModel.profileId

    signal applyChanges(Account account)

    width: parent.width

    onApplyChanges: {
        calendarModel.applyChanges(account)
    }

    SectionHeader {
        //% "Calendars"
        text: qsTrId("settings_accounts-la-calendars")
    }

    OnlineCalendarModel {
        id: calendarModel
    }

    Repeater {
        model: calendarModel

        TextSwitch {
            x: Theme.paddingSmall
            checked: model.enabled
            automaticCheck: false
            text: model.displayName
            onClicked: {
                calendarModel.setCalendarEnabled(model.index, !checked)
            }
        }
    }
}
