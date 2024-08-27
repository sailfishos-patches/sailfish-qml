import QtQuick 2.4
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0
import Nemo.Time 1.0
import Calendar.hourViewLayouter 1.0
import "Util.js" as Util

Item {
    id: dayPage

    readonly property alias date: flickable.date
    property int cellHeight: Math.max(fontMetrics.height, Theme.itemSizeSmall/2)
    property alias flickable: header

    readonly property string title: Util.capitalize(Format.formatDate(date, Formatter.WeekdayNameStandalone))
    readonly property string description: Format.formatDate(date, Formatter.DateLong)

    property Item tabHeader
    function attachHeader(tabHeader) {
        if (tabHeader) {
            tabHeader.parent = tabHeaderContainer
        }
        dayPage.tabHeader = tabHeader
    }
    function detachHeader() {
        dayPage.tabHeader = null
    }
    function gotoDate(date) {
        flickable.gotoDate(date)
    }

    function timeClicked(time) {
        pageStack.animatorPush("EventEditPage.qml", { defaultDate: time })
    }

    function timePressAndHold(time) {
        return // FIXME: this simply does not work
    }

    Connections {
        target: tabHeader
        onDateClicked: {
            var obj = pageStack.animatorPush("Sailfish.Silica.DatePickerDialog")
            obj.pageCompleted.connect(function(page) {
                page.accepted.connect(function() {
                    flickable.gotoDate(page.selectedDate)
                })
            })
        }
    }

    Component {
        id: eventDelegate
        DayPageEventDelegate {
            onPressAndHold: {
                var coord = mapToItem(flickable.contentItem, mouse.x, mouse.y)
                dayPage.timePressAndHold(coord.x, coord.y)
            }
        }
    }
    Component { id: overlapDelegate; DayPageOverlapDelegate {} }

    FontMetrics {
        id: fontMetrics
        font.pixelSize: Theme.fontSizeMedium
    }

    SilicaFlickable {
        id: header
        width: parent.width
        height: topContainer.height

        Column {
            id: topContainer
            width: parent.width
            spacing: isPortrait ? Theme.paddingLarge : Theme.paddingMedium

            Item {
                width: parent.width
                height: isPortrait ? (allDayList.height + tabHeaderContainer.height)
                    : Math.max(allDayList.height, tabHeaderContainer.height)

                Item {
                    id: tabHeaderContainer
                    width: isPortrait ? parent.width : (parent.width / 2)
                    height: dayPage.tabHeader ? dayPage.tabHeader.height : 0
                    x: isPortrait ? 0 : allDayList.width
                }

                ListView {
                    id: allDayList
                    height: dayPage.cellHeight
                    width: isPortrait ? parent.width : (parent.width / 2)
                    y: isPortrait ? tabHeaderContainer.height : ((parent.height - height) / 2)
                    interactive: false
                    layoutDirection: Qt.RightToLeft
                    orientation: ListView.Horizontal
                    clip: true // can be removed if Page starts clipping its content, bug 26058
                    model: AgendaModel {
                        filterMode: AgendaModel.FilterNonAllDay
                        startDate: flickable.date
                    }

                    delegate: DayPageEventDelegate {
                        width: allDayList.width / Math.min(2, allDayList.model.count)
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
                Image {
                    anchors.fill: parent
                    source: "image://theme/graphic-gradient-edge"
                    rotation: 180
                }
            }
        }
    }

    Item {
        id: flickableContainer

        anchors.top: header.bottom
        anchors.topMargin: -header.contentY
        height: parent.height - header.height
        width: parent.width
        visible: !dummyFlickable.visible

        Item {
            // flickable stays from date label to bottom, this item clips the view to avoid extra items on both ends
            height: parent.height - later.height
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
                var instanceId = contextMenu.event.modelObject.event.instanceId
                var startTime = contextMenu.event.modelObject.occurrence.startTime
                Remorse.itemAction(contextMenu.event, Remorse.deletedText, // TODO: Migrate DayPageEventDelegate to ListItem
                                                    function() { Calendar.remove(instanceId, startTime) })
            }
        }
        MenuItem {
            //% "New event"
            text: qsTrId("calendar-day-new_event")
            onClicked: pageStack.animatorPush("EventEditPage.qml", { defaultDate: contextMenu.date })
        }
    }
/*    ContextMenu {
        id: contextMenuAllDayEvent
        MenuItem {
            //% "Edit"
            text: qsTrId("calendar-day-edit")
        }
        MenuItem {
            //% "Delete"
            text: qsTrId("calendar-day-delete")
        }
    } */
    DayPageHeaderFooterEvent {
        id: later
        anchors.bottom: flickableContainer.bottom
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

