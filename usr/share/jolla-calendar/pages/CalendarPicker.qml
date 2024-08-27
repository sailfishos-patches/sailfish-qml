import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0
import Calendar.sortFilterModel 1.0
import Sailfish.Calendar 1.0

Page {
    id: root

    signal calendarClicked(string uid)
    property string selectedCalendarUid
    property bool hideExcludedCalendars

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: parent.width

            PageHeader {
                //: Header for page where calendar is selected for a event
                //% "Select calendar"
                title: qsTrId("calendar-he_select_calendar")
            }

            Repeater {
                model: SortFilterModel {
                    model: NotebookModel { }
                    filterRole: "readOnly"
                    filterRegExp: /false/
                    sortRole: "name"
                }

                delegate: BackgroundItem {
                    height: Math.max(calendarDelegate.height + 2*Theme.paddingSmall, Theme.itemSizeMedium)
                    onClicked: root.calendarClicked(model.uid)
                    visible: !model.excluded || !hideExcludedCalendars

                    CalendarSelectorDelegate {
                        id: calendarDelegate
                        accountIcon: model.accountIcon
                        calendarName: localCalendar ? CalendarTexts.getLocalCalendarName() : model.name
                        calendarDescription: model.description
                        selected: root.selectedCalendarUid === model.uid
                        width: calendarColor.x - 2*Theme.paddingLarge

                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                            margins: Theme.paddingLarge
                        }
                    }

                    Rectangle {
                        id: calendarColor

                        anchors {
                            right: parent.right
                            rightMargin: Theme.paddingLarge
                            verticalCenter: parent.verticalCenter
                        }
                        color: model.color
                        height: Theme.itemSizeExtraSmall
                        radius: Math.round(width / 3)
                        width: Theme.paddingSmall
                    }
                }
            }
        }
        VerticalScrollDecorator {}
    }
}
