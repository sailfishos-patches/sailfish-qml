import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Time 1.0
import org.nemomobile.calendar 1.0
import Nemo.Configuration 1.0

SlideshowView {
    id: view
    property date date: new Date()
    property var currentDate: date
    property int highlightedDay: -1
    property real contentY
    property int contentHeight
    property int headerHeight
    property real initialContentY

    onCurrentItemChanged: {
        if (currentItem) {
            if (currentItem.highlightedDate !== undefined) {
                view.currentDate = currentItem.highlightedDate
            }
            contentHeight = currentItem.contentHeight
            headerHeight = currentItem.headerHeight
            initialContentY = currentItem.initialContentY
        }
    }
    Connections {
        target: currentItem
        onHighlightedDateChanged: {
            if (currentItem.highlightedDate !== undefined) {
                view.currentDate = currentItem.highlightedDate
            }
        }
    }

    readonly property date refDate: { // This will correspond to model / 2, see weekToDate()
        var dt = new Date()
        dt.setHours(0, 0, 0, 0)
        var oneDateShift
        if (dt.getDay() < Qt.locale().firstDayOfWeek) {
            oneDateShift = 7 + dt.getDay() - Qt.locale().firstDayOfWeek
        } else {
            oneDateShift = dt.getDay() - Qt.locale().firstDayOfWeek
        }
        dt.setDate(dt.getDate() - oneDateShift)
        return dt
    }
    onDateChanged: {
        currentIndex = dateToWeek(date)
        var id = 6
        var dt = QtDate.addDays(weekToDate(currentIndex), 6)
        while (date < dt) {
            id -= 1
            dt.setDate(dt.getDate() - 1)
        }
        highlightedDay = id
    }

    clip: true
    itemWidth: width + Theme.paddingSmall + weekMetric.width + Theme.paddingLarge
    itemHeight: height
    cacheItemCount: 3

    WallClock {
        id: wallClock
        updateFrequency: WallClock.Minute
        enabled: Qt.application.active
    }

    TextMetrics {
        id: weekMetric
        //% "week %1"
        property string label: qsTrId("calendar-lbl-weekview_week_number")
        text: label.arg(56)
        font.pixelSize: Theme.fontSizeMedium
    }

    model: 10000
    currentIndex: dateToWeek(date)
    function weekToDate(weekId) {
        var dt = new Date(refDate)
        dt.setDate(dt.getDate() + 7 * (weekId - model / 2))
        return dt
    }
    function dateToWeek(dt) {
        return model / 2 + QtDate.daysTo(refDate, dt) / 7
    }

    delegate: WeekLayout {
        readonly property bool active: PathView.isCurrentItem
        oneDate: weekToDate(model.index)
        onDaySelected: view.highlightedDay = day
        width: view.width
        height: view.height
        weekText: weekMetric.label
        timeFormat: timeFormatConfig.value
        highlightedDay: view.highlightedDay
        Binding on contentY {
            when: active || moving
            value: view.contentY
        }
    }
    ConfigurationValue {
        id: timeFormatConfig
        key: "/sailfish/i18n/lc_timeformat24h"
    }
}
