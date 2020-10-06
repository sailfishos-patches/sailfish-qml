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

Page {
    id: root

    property var account
    property string serviceName
    property string serverAddress
    property string calendarPath

    signal finished(var success)

    backNavigation: !updateBusy.running

    onStatusChanged: {
        if (status === PageStatus.Active) {
            calendarUpdater.start(root.account,
                                  root.serviceName,
                                  root.serverAddress,
                                  root.calendarPath)
        }
    }

    BusyLabel {
        id: updateBusy

        running: calendarUpdater.status !== CaldavAccountCalendarUpdater.UnknownStatus
                 && calendarUpdater.status !== CaldavAccountCalendarUpdater.Finished
        text: calendarUpdater.statusText
    }

    InfoLabel {
        id: errorLabel
        anchors.bottom: updateBusy.bottom
    }

    CaldavAccountCalendarUpdater {
        id: calendarUpdater

        onSuccess: {
            root.finished(true)
        }

        onError: {
            console.log("Calendar update failed:", errorCode, errorString)
            errorLabel.text = errorString
            root.finished(false)
        }
    }
}
