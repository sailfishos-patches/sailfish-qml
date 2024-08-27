import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Calendar 1.0
import org.nemomobile.calendar 1.0

Page {
    property alias event: eventDetails.event
    property alias occurrence: eventDetails.occurrence

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column

            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                width: parent.width
                title: CalendarTexts.ensureEventTitle(eventDetails.event ? eventDetails.event.displayLabel : "")
                wrapMode: Text.Wrap
            }

            CalendarEventView {
                id: eventDetails
                showHeader: false
                showSelector: false

                onEventChanged: {
                    if (event) {
                        setAttendees(event.attendees)
                    }
                }
            }
        }

        VerticalScrollDecorator {}
    }
}
