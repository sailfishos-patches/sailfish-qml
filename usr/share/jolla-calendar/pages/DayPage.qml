import QtQuick 2.4
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0
import org.nemomobile.time 1.0
import Calendar.hourViewLayouter 1.0
import "Util.js" as Util

Page {
    id: dayPage

    property alias date: flickable.date
    property int cellHeight: Math.max(fontMetrics.height, Theme.itemSizeSmall/2)

    objectName: "DayPage"

    function timeClicked(time) {
        pageStack.animatorPush("EventEditPage.qml", { defaultDate: time })
    }

    function timePressAndHold(time) {
        return // FIXME: this simply does not work
    }

    Component { id: eventDelegate; DayPageEventDelegate {} }
    Component { id: overlapDelegate; DayPageOverlapDelegate {} }

    FontMetrics {
        id: fontMetrics
        font.pixelSize: Theme.fontSizeMedium
    }
    Image {
        width: parent.width
        height: topContainer.height + dateHeader.height
        source: "image://theme/graphic-gradient-edge"
        rotation: 180
    }

    Column {
        id: dateHeader
        width: parent.width

        FlippingPageHeader {
            animate: dayPage.status === PageStatus.Active
            width: parent.width
            title: Util.capitalize(Format.formatDate(flickable.date, Formatter.WeekdayNameStandalone))

            FlippingLabel {
                y: isPortrait ? Theme.itemSizeSmall : Theme.itemSizeExtraSmall
                animate: dayPage.status === PageStatus.Active
                width: parent.width
                text: Format.formatDate(flickable.date, Formatter.DateLong)
            }
        }

        Item {
            width: parent.width
            height: Theme.paddingLarge
        }
    }

    Column {
        id: topContainer

        width: parent.width
        anchors.top: dateHeader.bottom

        Item {
            id: allDayEventContainerContextMenu

            width: parent.width
            height: (allDayList.visible ? allDayList.height : 0) + contextMenuAllDayEvent.height

            ListView {
                id: allDayList
                height: dayPage.cellHeight
                width: parent.width
                interactive: false
                visible: count > 0
                layoutDirection: Qt.RightToLeft
                orientation: ListView.Horizontal
                clip: true // can be removed if Page starts clipping its content, bug 26058
                model: AgendaModel {
                    filterMode: AgendaModel.FilterNonAllDay
                    startDate: dayPage.date
                }

                delegate: DayPageEventDelegate {
                    width: events.width / 2
                    height: dayPage.cellHeight
                    // FIXME: long press to show context menu. contextMenuAllDayEvent currently unused
                }
            }
        }

        DayPageHeaderFooterEvent {
            id: earlier
            currentDate: flickable.date
            event: hourViewLayouter.earlierEvent
            width: parent.width
            onClicked: {
                var time = new Date(event.occurrence.startTime.getTime())

                if (event.event.allDay) {
                    time.setHours(8)
                } else {
                    time.setHours(time.getHours() - 2)
                }

                scrollAnimation.to = hourViewLayouter.timeToPosition(time)
                scrollAnimation.start()
            }
        }
    }

    Item {
        id: flickableContainer

        anchors.top: dateHeader.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        visible: !dummyFlickable.visible

        Item {
            // flickable stays from date label to bottom, this item clips the view to avoid extra items on both ends
            y: topContainer.height
            height: parent.height - topContainer.height - later.height
            width: parent.width
            clip: true

            DayTimesFlickable {
                id: flickable

                y: -parent.y
                height: flickableContainer.height
                width: flickableContainer.width

                Rectangle {
                    width: parent.width
                    height: Math.round(3 * Theme.pixelRatio)
                    y: {
                        var dayStartTime = new Date(currentTime.time.getTime())
                        dayStartTime.setHours(0, 0, 0, 0)
                        var dayStartPosition = hourViewLayouter.timeToPosition(dayStartTime)
                        var dayHeight = 48 * dayPage.cellHeight
                        var relativePosition = (currentTime.time.getHours()*60 + currentTime.time.getMinutes()) / (24*60)
                        var dayPosition = Math.min(dayHeight - height, (relativePosition * dayHeight))
                        return dayStartPosition + dayPosition
                    }
                    color: Theme.secondaryHighlightColor

                    WallClock {
                        id: currentTime
                        updateFrequency: WallClock.Minute
                        enabled: Qt.application.active
                    }
                }

                Item {
                    id: events
                    width: parent.width - (Screen.sizeCategory > Screen.Medium ? Theme.horizontalPageMargin : 0)

                    HourViewLayouter {
                        id: hourViewLayouter

                        model: AgendaModel {
                            startDate: QtDate.addDays(flickable.date, -7)
                            endDate: QtDate.addDays(flickable.date, 7)
                        }
                        delegate: eventDelegate
                        overlapDelegate: overlapDelegate
                        delegateParent: events
                        visibleY: flickable.contentY
                        height: flickable.height
                        width: events.width
                        cellHeight: dayPage.cellHeight
                        daySeparatorHeight: flickable.pageHeaderHeight
                        startDate: flickable.startDate
                        currentDate: flickable.date
                    }
                }

                NumberAnimation {
                    id: scrollAnimation
                    target: flickable
                    property: "contentY"
                    duration: 400
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    // This horrible hack exists because we want the animation behavior of a regular context menu,
    // but we want to split the day view apart when it appears.  Anything else looks very silly.
    Flickable {
        id: dummyFlickable
        y: flickableContainer.y
        height: flickable.height
        width: parent.width
        contentHeight: flickable.contentHeight
        visible: contextMenu.height != 0

        property real splitY
        property real initialY

        ShaderEffectSource {
            id: dummyFlickableSource
            sourceItem: dummyFlickable.visible?flickableContainer:null
            hideSource: true
        }

        children: [
            Item {
                width: parent.width
                height: contextMenu.y - dummyFlickable.contentY

                FadeEffect {
                    anchors.fill: parent
                    source: dummyFlickableSource
                    fadeMode: 1
                    fade: 0
                    sourceOffset: dummyFlickable.splitY - height
                    sourceHeight: height
                }
            },

            Item {
                y: (contextMenu.y + contextMenu.height - dummyFlickable.contentY)
                width: parent.width
                height: parent.height - y

                FadeEffect {
                    anchors.fill: parent
                    source: dummyFlickableSource
                    fadeMode: 2
                    fade: 0
                    sourceOffset: dummyFlickable.splitY
                    sourceHeight: height
                }
            }
        ]

        Item {
            id: contextMenu

            property Item event
            property date date

            height: (contextMenuEvent.parent == contextMenu) ? contextMenuEvent.height : contextMenuBasic.height
        }
    }

    // We use two ContextMenu's as sometimes the layout (and thus the animation) doesn't work correctly
    // if you just set the visibility of the various MenuItems.
    ContextMenu {
        id: contextMenuBasic
        MenuItem {
            //% "New event"
            text: qsTrId("calendar-day-new_event")
            onClicked: pageStack.animatorPush("EventEditPage.qml", { defaultDate: contextMenu.date })
        }
    }
    ContextMenu {
        id: contextMenuEvent
        MenuItem {
            //% "Edit"
            text: qsTrId("calendar-day-edit")
            onClicked: pageStack.animatorPush("EventEditPage.qml", { event: contextMenu.event.modelObject })
        }
        MenuItem {
            //% "Delete"
            text: qsTrId("calendar-day-delete")
            onClicked: {
                var uid = contextMenu.event.modelObject.event.uniqueId
                var recurrenceId = contextMenu.event.modelObject.event.recurrenceId
                var startTime = contextMenu.event.modelObject.occurrence.startTime
                Remorse.itemAction(contextMenu.event, Remorse.deletedText, // TODO: Migrate DayPageEventDelegate to ListItem
                                                    function() { Calendar.remove(uid, recurrenceId, startTime) })
            }
        }
        MenuItem {
            //% "New event"
            text: qsTrId("calendar-day-new_event")
            onClicked: pageStack.animatorPush("EventEditPage.qml", { defaultDate: contextMenu.date })
        }
    }
    ContextMenu {
        id: contextMenuAllDayEvent
        MenuItem {
            //% "Edit"
            text: qsTrId("calendar-day-edit")
        }
        MenuItem {
            //% "Delete"
            text: qsTrId("calendar-day-delete")
        }
    }
    DayPageHeaderFooterEvent {
        id: later
        anchors.bottom: parent.bottom
        currentDate: flickable.date
        event: hourViewLayouter.laterEvent
        width: parent.width

        onClicked: {
            var time = new Date(event.occurrence.startTime.getTime())
            if (event.event.allDay) {
                time.setHours(3)
            } else {
                time.setHours(time.getHours() - 2)
            }

            scrollAnimation.to = hourViewLayouter.timeToPosition(time)
            scrollAnimation.start()
        }

        Image {
            anchors.fill: parent
            source: "image://theme/graphic-gradient-edge"
        }
    }
}

