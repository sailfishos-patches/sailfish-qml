/*
 * Copyright (c) 2013 - 2019 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

Column {
    id: root

    property alias accountId: calendarModel.accountId
    property alias valid: calendarModel.valid

    property bool _modified

    function applyChanges(account) {
        if (_modified) {
            calendarModel.applyChanges(account)
        }
    }

    width: parent.width

    SectionHeader {
        //% "Calendars"
        text: qsTrId("settings_accounts-la-calendars")
    }

    InfoLabel {
        visible: calendarModel.count === 0
        //% "No calendars found"
        text: qsTrId("settings_accounts-la-no_calendars_found")
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
                root._modified = true
                calendarModel.setCalendarEnabled(model.index, !checked)
            }
        }
    }
}
