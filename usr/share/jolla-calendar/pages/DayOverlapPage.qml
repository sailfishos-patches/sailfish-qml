import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Calendar 1.0
import org.nemomobile.calendar 1.0
import "Util.js" as Util

Page {
    id: root

    property alias model: eventList.model
    property date date

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content
            width: parent.width

            PageHeader {
                id: pageHeader
                title: Util.capitalize(Format.formatDate(root.date, Formatter.WeekdayNameStandalone))
            }
            Text {
                y: Theme.itemSizeSmall
                anchors {
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                }
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeMedium
                text: Format.formatDate(root.date, Formatter.DateLong)
            }

            Repeater {
                model: AgendaModel {
                    filterMode: AgendaModel.FilterNonAllDay
                    startDate: root.date
                }

                delegate: CalendarEventListDelegate {
                    width: parent.width
                    activeDay: root.date
                    onClicked: {
                        pageStack.animatorPush("EventViewPage.qml",
                            {   instanceId: model.event.instanceId,
                                startTime: model.occurrence.startTime,
                                'remorseParent': root
                            })
                    }
                }
            }

            Repeater {
                id: eventList
                delegate: CalendarEventListDelegate {
                    width: parent.width
                    activeDay: root.date
                    onClicked: {
                        pageStack.animatorPush("EventViewPage.qml",
                            {   instanceId: model.event.instanceId,
                                startTime: model.occurrence.startTime,
                                'remorseParent': root
                            })
                    }
                }
            }
        }
    }
}
