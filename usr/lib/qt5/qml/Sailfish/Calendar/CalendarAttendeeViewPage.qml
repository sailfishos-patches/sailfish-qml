import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0

Page {
    id: root

    property var attendeeList

    onAttendeeListChanged: {
        attendeeModel.doFill(attendeeList)
    }

    SilicaListView {
        id: attendeeView

        anchors.fill: parent
        model: AttendeeModel {
            id: attendeeModel
        }

        header: PageHeader {
            //% "People"
            title: qsTrId("sailfish_calendar-la-people")
        }

        delegate: CalendarAttendeeDelegate {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            name: model.name
            secondaryText: model.email
            participationStatus: model.participationStatus
        }

        section {
            property: "participationSection"
            criteria: ViewSection.FullString

            delegate: SectionHeader {
                text: _sectionDelegateText(section)
                height: text === "" ? 0 : Theme.itemSizeSmall
                horizontalAlignment: Text.AlignRight

                function _sectionDelegateText(section) {
                    //assuming javascript handling string and enum comparison
                    if (section == AttendeeModel.OrganizerSection) {
                        //% "Organizer"
                        return qsTrId("sailfish-calendar-la-event_organizer_attendee")
                    } else if (section == AttendeeModel.OptionalSection) {
                        //% "Optional"
                        return qsTrId("sailfish-calendar-la-event_optional_attendee")
                    } else if (section == AttendeeModel.RequiredSection) {
                        //% "Required"
                        return qsTrId("sailfish-calendar-la-event_required_attendee")
                    }
                    return ""
                }
            }
        }
    }
}
