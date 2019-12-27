import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.time 1.0
import org.nemomobile.calendar 1.0

CoverBackground {
    Label {
        //% "New event"
        text: qsTrId("calendar-la-new_event")
        x: Theme.paddingLarge
        visible: !eventList.count
        width: parent.width - 2*Theme.paddingLarge
        color: Theme.secondaryColor
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        anchors {
            bottom: parent.bottom
            bottomMargin: Theme.itemSizeLarge
        }
    }

    CoverActionList {
        CoverAction {
            iconSource: "image://theme/icon-cover-new"
            onTriggered: {
                app.activate()
                app.showMainPage(PageStackAction.Immediate)
                pageStack.push("../pages/EventEditPage.qml", {}, PageStackAction.Immediate)
            }
        }
    }
    Column {
        x: Theme.paddingLarge
        spacing: Theme.paddingSmall
        width: parent.width - 2*Theme.paddingLarge
        anchors {
            top: parent.top
            bottom: coverActionArea.top
        }

        DateLabel {
            id: dateLabel

            day: Qt.formatDate(wallClock.time, "d")
            weekDay: capitalize(Format.formatDate(wallClock.time, Formatter.WeekdayNameStandalone))
            month: capitalize(Format.formatDate(wallClock.time, Formatter.MonthNameStandalone))

            function capitalize(string) {
                return string.charAt(0).toUpperCase() + string.substr(1)
            }

            WallClock {
                id: wallClock

                // TODO: only update when Switcher is visible
                enabled: !app.applicationActive
                updateFrequency: WallClock.Day
                onSystemTimeUpdated: {
                    eventUpdater.interval = 1000
                    eventUpdater.update()
                }
            }
        }
        Item {
            width: parent.width + Theme.paddingLarge
            height: parent.height - dateLabel.height - parent.spacing

            ListModel {
                id: activeAndComing
            }

            Timer {
                id: eventUpdater

                onTriggered: update()

                function update() {
                    activeAndComing.clear()

                    var now = new Date
                    var nextEnding = undefined

                    for (var i = 0; i < allEvents.count; ++i) {
                        var occurrence = allEvents.get(i, AgendaModel.OccurrenceObjectRole)
                        var event = allEvents.get(i, AgendaModel.EventObjectRole)

                        if (event.allDay || now < occurrence.endTime) {
                            activeAndComing.append({ displayLabel: event.displayLabel, allDay: event.allDay,
                                                       startTime: occurrence.startTime, endTime: occurrence.endTime,
                                                       color: event.color })

                            if (!event.allDay && (nextEnding == undefined || occurrence.endTime < nextEnding)) {
                                nextEnding = occurrence.endTime
                            }
                        }
                    }

                    if (nextEnding !== undefined) {
                        var timeout = Math.max(0, nextEnding.getTime() - now.getTime() + 1000)
                        if (timeout > 0) {
                            eventUpdater.interval = timeout
                            eventUpdater.start()
                        } else {
                            eventUpdater.stop()
                        }
                    } else {
                        eventUpdater.stop()
                    }
                }
            }

            AgendaModel {
                id: allEvents
                startDate: wallClock.time
                onUpdated: eventUpdater.update()
            }

            ListView {
                id: eventList

                property int eventHeight: (parent.height - Theme.paddingSmall - spacing)/2

                clip: true
                model: activeAndComing
                interactive: false
                width: parent.width
                height: 2*eventHeight + spacing
                spacing: Theme.paddingSmall
                visible: count > 0

                delegate: CoverEventItem {
                    eventName: model.displayLabel
                    allDay: model.allDay
                    startTime: model.startTime
                    endtime: model.endTime
                    activeDay: wallClock.time
                    color: model.color
                    height: eventList.eventHeight
                }
            }
            OpacityRampEffect {
                offset: 0.5
                sourceItem: eventList
            }
        }
    }
}
