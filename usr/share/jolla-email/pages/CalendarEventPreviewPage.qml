/*
 * Copyright (c) 2017 - 2019 Jolla Ltd.
 * Copyright (c) 2020 - 2021 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Calendar 1.0
import org.nemomobile.calendar 1.0
import Nemo.DBus 2.0

Page {
    id: root
    property alias icsString: importModel.icsString
    property alias event: eventDetails.event
    property alias occurrence: eventDetails.occurrence
    property alias cancellation: eventDetails.cancellation

    ImportModel {
        id: importModel
        onCountChanged: {
            if (count > 0) {
                eventDetails.event = getEvent(0)
                eventDetails.occurrence = eventDetails.event ? eventDetails.event.nextOccurrence() : null
            } else {
                eventDetails.event = null
                eventDetails.occurrence = null
            }
        }
    }

    DBusInterface {
        id: calendarDBusInterface
        service: "com.jolla.calendar.ui"
        path: "/com/jolla/calendar/ui"
        iface: "com.jolla.calendar.ui"
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        PullDownMenu {
            visible: icsString !== "" && !cancellation
            MenuItem {
                //% "Import into Calendar"
                text: qsTrId("sailfish_calendar-me-import_event_in_calendar")
                onClicked: {
                    calendarDBusInterface.call("importIcsData", [root.icsString])
                    pageStack.pop()
                }
            }
        }

        Column {
            id: column

            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                width: parent.width
                title: eventDetails.event ? eventDetails.event.displayLabel : ""
                wrapMode: Text.Wrap
            }

            CalendarEventView {
                id: eventDetails
                showHeader: false
                showSelector: false
            }
        }
        VerticalScrollDecorator {}
    }
}
