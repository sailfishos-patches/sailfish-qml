import QtQuick 2.6
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0
import Calendar.hourViewLayouter 1.0

Item {
    id: root
    property int fromHour: 0
    property int toHour: 24
    property string weekText: "week %1"
    property string timeFormat: "24"
    property int minHourHeight: Math.max(2*fontDef.height, Theme.itemSizeSmall)
    property date oneDate: new Date()
    property int oneDateShift: -1
    property int highlightedDay: -1
    readonly property var highlightedDate: {
        if (highlightedDay >= 0) {
            var dt = new Date(_firstDay)
            dt.setDate(dt.getDate() + highlightedDay)
            return dt
        } else {
            return undefined
        }
    }
    property alias contentY: content.contentY
    property int contentHeight: header.height + days.height
    property alias headerHeight: header.height
    property real initialContentY: days.oneHourHeight * (8 - fromHour)
    property date _firstDay

    signal daySelected(int day)

    onOneDateChanged: {
        if (oneDate.getFullYear() < 0)
            return
        var dt = new Date(oneDate)
        dt.setHours(12, 0, 0, 0)
        if (dt.getDay() < Qt.locale().firstDayOfWeek) {
            oneDateShift = 7 + dt.getDay() - Qt.locale().firstDayOfWeek
        } else {
            oneDateShift = dt.getDay() - Qt.locale().firstDayOfWeek
        }
        dt.setDate(dt.getDate() - oneDateShift)
        _firstDay = dt
    }

    Column {
        id: header
        spacing: Theme.paddingSmall
        x: background.horizontalShift
        width: days.width

        Row {
            height: daysHeader.count > 0 ? daysHeader.itemAt(0).height : 0
            Repeater {
                id: daysHeader
                model: 7
                delegate: Column {
                    id: dayColumn
                    property date date: {
                        var dt = new Date(root._firstDay)
                        dt.setDate(dt.getDate() + modelData)
                        dt.setHours(12, 0)
                        return dt
                    }
                    property bool isToday: date.getDate() === wallClock.time.getDate()
                            && date.getMonth() === wallClock.time.getMonth()
                            && date.getFullYear() === wallClock.time.getFullYear()
                    width: days.dayWidth
                    Label {
                        text: Qt.formatDateTime(dayColumn.date, "ddd")
                        color: modelData == root.highlightedDay ? Theme.highlightColor : Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                        font.bold: isToday
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Label {
                        text: dayColumn.date.getDate()
                        color: modelData == root.highlightedDay ? Theme.highlightColor : Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: isToday
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }

        Item {
            id: fullDays
            property int maxConcurrentFullDays: height / Theme.paddingMedium
            property int nConcurrentFullDays: 1
            property real itemHeight: height / nConcurrentFullDays
            property var lastFreeDay: {
                var arr = new Array(maxConcurrentFullDays)
                reset(arr)
                return arr
            }
            function reset(arr) {
                if (arr) {
                    for (var i = 0; i < arr.length; i++) {
                        arr[i] = -1
                    }
                }
            }
            function relayout() {
                reset(fullDays.lastFreeDay)
                var n = 0
                for (var it = 0; it < fullDaysModel.count; it++) {
                    var item = fullDaysItems.itemAt(it)
                    item.lane = -1
                    for (var i = 0; i < fullDays.lastFreeDay.length; i++) {
                        if (fullDays.lastFreeDay[i] <= item.startDay) {
                            fullDays.lastFreeDay[i] = item.startDay + item.duration
                            item.lane = i
                            n = Math.max(n, i)
                            break
                        }
                    }
                    if (item.x < 0) console.warn("not enough space to accomodate full day.")
                }
                nConcurrentFullDays = n + 1
            }
            // Ensure we have at least two concurrent full day event with text
            height: Math.max(Theme.itemSizeSmall,
                2 * (Theme.paddingSmall + fullDaysItems.barHeight + fontDef.height))
            width: parent.width
            Repeater {
                id: fullDaysItems
                property int barHeight: Theme.paddingSmall
                model: AgendaModel {
                    id: fullDaysModel
                    startDate: root._firstDay
                    endDate: QtDate.addDays(root._firstDay, 6)
                    filterMode: AgendaModel.FilterNonAllDay
                    onUpdated: fullDays.relayout()
                }
                delegate: BackgroundItem {
                    property int startDay: {
                        var st = Math.max(fullDaysModel.startDate.getTime(),
                            model.occurrence.startTime.getTime())
                        return (st - fullDaysModel.startDate.getTime()) / 86400000
                    }
                    property int duration: {
                        var st = Math.max(fullDaysModel.startDate.getTime(),
                            model.occurrence.startTime.getTime())
                        var et = Math.min(fullDaysModel.endDate.getTime(),
                           model.occurrence.endTime.getTime())
                        return (et - st) / 86400000 + 1
                    }
                    property int lane: -1

                    x: days.dayWidth * startDay
                    y: lane * fullDays.itemHeight
                    width: days.dayWidth * duration
                    height: fullDays.itemHeight
                    visible: lane >= 0 && duration > 0
                    Rectangle {
                        id: fullDayBar
                        color: model.event.color
                        y: Math.round(0.5 * Theme.paddingSmall)
                        x: Theme.paddingSmall
                        width: parent.width - 2 * Theme.paddingSmall
                        height: fullDaysItems.barHeight
                        radius: height / 3
                    }
                    Label {
                        id: fullDayLabel
                        width: parent.width
                        visible: height >= fontDef.height
                        y: fullDayBar.y + fullDayBar.height
                        height: parent.height - y
                        wrapMode: Text.Wrap
                        clip: true
                        text: model.event.displayLabel
                        font.pixelSize: textRef.font.pixelSize
                        font.strikeout: model.event.status == CalendarEvent.StatusCancelled
                    }
                    OpacityRampEffect {
                        enabled: fullDayLabel.implicitHeight > fullDayLabel.height
                        direction: OpacityRamp.TopToBottom
                        sourceItem: fullDayLabel
                        slope: Math.max(1, fullDayLabel.height / Theme.paddingLarge)
                        offset: 1 - 1 / slope
                    }
                    onClicked: {
                        pageStack.animatorPush("EventViewPage.qml",
                            { instanceId: model.event.instanceId,
                              startTime: model.occurrence.startTime,
                              'remorseParent': root
                            })
                    }
                }
            }
        }
    }

    Item {
        id: content
        width: parent.width
        height: parent.height - header.height

        property real contentY: root.initialContentY
        anchors.top: header.bottom
        clip: true

        Item {
            id: background
            property real sidePanelPadding: Theme.paddingSmall
            property real horizontalShift: Theme.paddingSmall + hourRef.width + sidePanelPadding
            width: parent.width
            y: Math.max(-content.contentY, root.height - root.contentHeight)

            Repeater {
                model: root.toHour - root.fromHour
                delegate: Item {
                    Rectangle {
                        id: hourRectangle
                        y: modelData * days.oneHourHeight
                        width: background.width
                        height: days.oneHourHeight
                        color: Theme.primaryColor
                        opacity: 0.05
                        visible: modelData & 1
                    }
                    Label {
                        width: hourRef.width
                        text: {
                            var dt = new Date
                            dt.setHours(root.fromHour + modelData, 0)
                            if (root.timeFormat === "24") {
                                return Format.formatDate(dt, Format.TimeValueTwentyFourHours)
                            } else {
                                return Format.formatDate(dt, Format.TimeValueTwelveHours)
                            }
                        }
                        anchors {
                            left: hourRectangle.left
                            leftMargin: Theme.paddingSmall
                            top: hourRectangle.top
                        }
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.highlightColor
                        opacity: modelData & 1 ? Theme.opacityHigh : Theme.opacityLow
                    }
                }
            }
            TextMetrics {
                id: hourRef
                text: {
                    var dt = new Date
                    dt.setHours(23, 0)
                    return Format.formatDate(dt, Format.TimeValueTwentyFourHours)
                }
                font.pixelSize: Theme.fontSizeSmall
            }
            Rectangle {
                width: parent.width
                height: Theme.paddingSmall / 2
                color: Theme.secondaryHighlightColor
                opacity: 0.5
                x: background.horizontalShift
                y: Math.max(0, days.oneHourHeight * (wallClock.time.getHours()
                    + wallClock.time.getMinutes() / 60 - root.fromHour) - height / 2)
                visible: dayItems.count > 0
                    && wallClock.time.getHours() >= root.fromHour
                    && wallClock.time.getHours() < root.toHour
                    && wallClock.time >= dayItems.itemAt(0).fromDate
                    && wallClock.time < dayItems.itemAt(6).toDate
            }
        }

        Row {
            id: days
            property real dayWidth: width / 7
            property real oneHourHeight: Math.max(root.minHourHeight, (root.height - content.y) / (toHour - fromHour))
            x: background.horizontalShift
            y: background.y
            width: parent.width - x
            height: (root.toHour - root.fromHour) * oneHourHeight

            Repeater {
                id: dayItems
                model: 7
                delegate: Item {
                    id: agenda
                    property date fromDate: {
                        var dt = new Date(root._firstDay)
                        dt.setDate(dt.getDate() + modelData)
                        dt.setHours(root.fromHour, 0)
                        return dt
                    }
                    property date toDate: {
                        var dt = new Date(fromDate)
                        dt.setHours(root.toHour, 59, 59)
                        return dt
                    }
                    property bool isToday: fromDate.getDate() === wallClock.time.getDate()
                        && fromDate.getMonth() === wallClock.time.getMonth()
                        && fromDate.getFullYear() === wallClock.time.getFullYear()
                    width: days.dayWidth
                    height: (root.toHour - root.fromHour) * days.oneHourHeight

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.daySelected(modelData)
                    }

                    Rectangle {
                        height: parent.height
                        width: Math.round(Theme.pixelRatio)
                        color: Theme.secondaryHighlightColor
                        visible: modelData > 0
                    }

                    Rectangle {
                        width: days.dayWidth - 2 * Theme.paddingSmall
                        height: Theme.paddingSmall / 2
                        color: Theme.highlightColor
                        radius: height / 2
                        visible: agenda.isToday
                        y: Math.max(0, days.oneHourHeight * (wallClock.time.getHours() + wallClock.time.getMinutes() / 60 - root.fromHour) - height / 2)
                        x: Theme.paddingSmall
                        z: 0
                    }

                    HourViewLayouter {
                        model: AgendaModel {
                            filterMode: AgendaModel.FilterAllDay
                            startDate: agenda.fromDate
                        }
                        width: agenda.width
                        height: agenda.height
                        cellHeight: days.oneHourHeight / 2
                        delegate: eventDelegate
                        overlapDelegate: overflowDelegate
                        delegateParent: agenda
                        startDate: agenda.fromDate
                        currentDate: agenda.fromDate
                        maximumConcurrency: Math.max(2, days.dayWidth / (3 * Theme.paddingSmall + textRef.width))
                    }
                }
            }
        }
    }

    Label {
        id: weekLabel
        property date thursday: {
            var date = new Date(root._firstDay)
            date.setHours(0, 0, 0, 0)
            // Thursday in current week decides the year.
            date.setDate(date.getDate() + 3 - (date.getDay() + 6) % 7)
            return date
        }
        anchors {
            top: content.top
            topMargin: days.oneHourHeight - height / 2
            right: content.left
            rightMargin: Theme.paddingSmall
        }
        text: {
            // Source: https://weeknumber.com/how-to/javascript
            // January 4 is always in week 1.
            var week1 = new Date(thursday.getFullYear(), 0, 4)
            // Adjust to Thursday in week 1 and count number of weeks from date to week1.
            var weekId = 1 + Math.round(((thursday.getTime() - week1.getTime()) / 86400000
                                         - 3 + (week1.getDay() + 6) % 7) / 7)
            return root.weekText.arg(weekId)
        }
        color: Theme.secondaryHighlightColor
    }
    Label {
        anchors {
            top: content.top
            topMargin: 3 * days.oneHourHeight - height / 2
            right: weekLabel.right
        }
        text: weekLabel.thursday.getFullYear()
        color: Theme.secondaryHighlightColor
    }

    TextMetrics {
        id: textRef
        text: "m"
        font.pixelSize: Theme.fontSizeExtraSmall
    }
    FontMetrics {
        id: fontDef
        font.pixelSize: Theme.fontSizeExtraSmall
    }
    Component {
        id: eventDelegate
        DayPageEventDelegate {
            fontSize: Theme.fontSizeExtraSmall
            oneLiner: false
            onClicked: root.daySelected((7 + date.getDay() - Qt.locale().firstDayOfWeek) % 7)
        }
    }
    Component {
        id: overflowDelegate
        DayPageOverlapDelegate {
            fontSize: Theme.fontSizeExtraSmall
            oneLiner: false
            onClicked: root.daySelected((7 + date.getDay() - Qt.locale().firstDayOfWeek) % 7)
        }
    }
}
