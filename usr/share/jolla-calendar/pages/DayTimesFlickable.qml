import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0

SilicaFlickable {
    id: root

    default property alias timesData: events.data

    property date date: new Date

    property date startDate: new Date(1980, 0, 1)
    property date endDate: new Date(2199, 11, 31)
    property int pageHeaderHeight: Theme.itemSizeSmall
    property real previousDayHeight

    property int _maxDay: 1 + Math.floor(Math.max(0, _stripTime(endDate) - _stripTime(startDate)) / 86400000)

    function gotoDate(date) {
        var day = QtDate.daysTo(_stripTime(startDate), date);
        contentY = day * day1.height + date.getHours() * 2*dayPage.cellHeight
        _updateDayBackground()
    }

    function _stripTime(date) {
        return new Date(date.getFullYear(), date.getMonth(), date.getDate())
    }

    function _updateDayBackground() {
        if (!day1.height) return

        var cw = Math.max(0, contentY)
        var day = Math.floor(cw / day1.height)

        previousDayHeight = day1.height
        day1.y = day * day1.height
        day2.y = (day + 1) * day1.height
        date = QtDate.addDays(_stripTime(startDate), day)
        day1.date = date
        day2.date = QtDate.addDays(date, 1)

        if (day + 1 >= _maxDay) {
            day2.visible = false
        } else {
            day2.visible = true
        }
    }

    function daysForDate(date)
    {
        return Math.max(0, QtDate.daysTo(_stripTime(startDate), date))
    }

    quickScroll: false
    contentHeight: _maxDay * day1.height
    onContentYChanged: _updateDayBackground()
    Component.onCompleted: gotoDate(date)

    DayTimesBackground { id: day1; pageHeaderHeight: root.pageHeaderHeight }
    DayTimesBackground { id: day2; pageHeaderHeight: root.pageHeaderHeight }

    Item {
        id: events
        anchors.left: day1.right
        anchors.right: parent.right
    }

    // Update geometry if the cell height changes, do asyncronously
    // so positioners have time to calculate correct day height
    Connections {
        target: dayPage
        onCellHeightChanged: lateUpdateDayBackgroundTimer.restart()
    }

    Timer {
        id: lateUpdateDayBackgroundTimer
        interval: 10
        onTriggered: {
            if (day1.height !== previousDayHeight) {
                // If day height has changed the current contentY has become invalid, fix it
                root.contentY = root.contentY*day1.height/previousDayHeight
                _updateDayBackground()
            }
        }
    }
}

