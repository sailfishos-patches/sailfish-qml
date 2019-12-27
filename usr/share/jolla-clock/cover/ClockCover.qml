import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Timezone 1.0
import org.nemomobile.time 1.0
import org.nemomobile.alarms 1.0
import com.jolla.clock.private 1.0
import "../common"

CoverBackground {
    id: root

    property bool update: status === Cover.Active || Qt.application.active

    property bool _stopwatchMode: mainWindow.stopwatchMode || (stopwatch && stopwatch.running)

    allowResize: true

    property int _maximumItems: height >= Theme.coverSizeLarge.height
                                ? 2
                                : height >= Theme.coverSizeSmall.height ? 1 : 0

    Item {
        id: contents

        width: Theme.coverSizeLarge.width
        height: Theme.coverSizeLarge.height
        property real xScale: root.width / contents.width

        transform: Scale {
            xScale: contents.xScale
            yScale: root.height / contents.height
        }

        ClockView {
            id: clockView

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: Theme.paddingLarge
            }
            height: width

            time: wallClock.time
        }

        ClockItem {
            id: timeLabel

            time: wallClock.time
            color: Theme.primaryColor
            secondaryColor: Theme.secondaryColor
            primaryPixelSize: Theme.fontSizeExtraLarge

            height: parent.height - clockView.height - clockView.y - coverActionArea.height/contents.xScale
            visible: alarmsView.count === 0 && timersView.count === 0 && !_stopwatchMode
            anchors {
                top: clockView.bottom
                horizontalCenter: parent.horizontalCenter
            }
        }

        TimeListView {
            id: alarmsView

            onLayoutDataChanged: _calculatePaddings()

            // TODO: only display enabled alarms once org.nemomobile.time alarm model supports filtering

            model: enabledAlarmsModel
            maximumCount: _stopwatchMode ? 0 : (_maximumItems - timersView.visualCount)
            visible: count > 0 && !_stopwatchMode

            anchors {
                top: clockView.bottom
                topMargin: Theme.paddingMedium
                left: parent.left
                leftMargin: Theme.paddingLarge
                right: parent.right
                rightMargin: Theme.paddingLarge
            }

            delegate: CoverAlarmItem {
                property int itemIndex: model.index

                height: alarmsView.itemHeight
                width: alarmsView.width

                prePadding: alarmsView.paddingData[index] ? alarmsView.paddingData[index].pre : 0
                postPadding: alarmsView.paddingData[index] ? alarmsView.paddingData[index].post : 0

                color: Clock.hueShift(model.index, alarmsView.count, Theme.highlightColor)

                time: {
                    var date = new Date
                    date.setHours(model.alarm.hour)
                    date.setMinutes(model.alarm.minute)
                    return date
                }

                title: model.title

                Component.onCompleted: updateLayoutData()
                onPreTextWidthChanged: updateLayoutData()
                onTimeTextWidthChanged: updateLayoutData()
                onPostTextWidthChanged: updateLayoutData()
                onItemIndexChanged: updateLayoutData()

                function updateLayoutData() {
                    alarmsView.updateLayoutData(index, preTextWidth, timeTextWidth, postTextWidth)
                }
            }
        }

        TimeListView {
            id: timersView

            property bool largeMode: _maximumItems > 1 && timersView.count === 1 && alarmsView.count === 0

            onLayoutDataChanged: _calculatePaddings()

            // TODO: only display active timers once timer model stores the progress and running status

            model: enabledTimersModel
            maximumCount: _stopwatchMode ? 0 : _maximumItems
            visible: count > 0 && !_stopwatchMode

            anchors {
                top: alarmsView.visible ? alarmsView.bottom : clockView.bottom
                topMargin: alarmsView.visible ? 0 : Theme.paddingMedium
                left: parent.left
                leftMargin: Theme.paddingLarge
                right: parent.right
                rightMargin: Theme.paddingLarge
            }

            itemHeight: largeMode ? Theme.itemSizeMedium : Theme.itemSizeSmall/2

            delegate: CoverTimerItem {
                property int itemIndex: model.index

                height: timersView.itemHeight
                width: timersView.width

                largeMode: timersView.largeMode

                prePadding: timersView.paddingData[index] ? timersView.paddingData[index].pre : 0
                postPadding: timersView.paddingData[index] ? timersView.paddingData[index].post : 0

                Component.onCompleted: updateLayoutData()
                onTimeTextWidthChanged: updateLayoutData()
                onItemIndexChanged: updateLayoutData()

                function updateLayoutData() {
                    timersView.updateLayoutData(index, 0, timeTextWidth, 0)
                }
            }
        }

        LargeItem {
            id: stopwatchView

            property int seconds: Math.floor((stopwatch ? stopwatch.totalTime : 0) / 1000)

            anchors {
                top: timersView.bottom
                leftMargin: Theme.paddingLarge
                rightMargin: Theme.paddingLarge
            }

            visible: _stopwatchMode
            titleVisible: _maximumItems > 1

            //% "Stopwatch"
            title: qsTrId("jolla-clock-la-stopwatch")
        }

        WallClock {
            id: wallClock
            enabled: root.update
            updateFrequency: WallClock.Minute
        }

        TimezoneLocalizer {
            id: localizer
            timezone: wallClock.timezone
        }

        EnabledAlarmsProxyModel {
            id: enabledAlarmsModel
            model: alarmsModel
        }
        EnabledAlarmsProxyModel {
            id: enabledTimersModel
            model: timersModel
        }
    }

    function _calculatePaddings() {
        var layoutMax = { pre: 0, time: 0, post: 0 }

        var views = [alarmsView, timersView]

        for (var j = 0; j < views.length; ++j) {
            if (views[j].layoutData === undefined)
                continue

            for (var i = 0; i < views[j].layoutData.length; ++i) {
                layoutMax.pre = Math.max(layoutMax.pre, views[j].layoutData[i].pre)
                layoutMax.time = Math.max(layoutMax.time, views[j].layoutData[i].time)
                layoutMax.post = Math.max(layoutMax.post, views[j].layoutData[i].post)
            }
        }

        var preClockPadding = layoutMax.pre > 0 ? Theme.paddingSmall : Theme.paddingMedium
        var postClockPadding = layoutMax.post > 0 ? Theme.paddingSmall : Theme.paddingMedium

        for (j = 0; j < views.length; ++j) {
            if (views[j].layoutData === undefined)
                continue

            var newPaddingData = views[j].paddingData
            if (newPaddingData === undefined)
                newPaddingData = new Array

            for (i = 0; i < views[j].layoutData.length; ++i) {
                var padding = newPaddingData[i]
                if (padding === undefined)
                    padding = new Object
                padding.pre = preClockPadding + layoutMax.pre - views[j].layoutData[i].pre
                padding.post = postClockPadding + layoutMax.post - views[j].layoutData[i].post
                var extra = layoutMax.time - views[j].layoutData[i].time
                if (layoutMax.pre > 0)
                    padding.post += extra
                else
                    padding.pre += extra
                newPaddingData[i] = padding
            }
            views[j].paddingData = newPaddingData
        }
    }

    CoverActionList {
        enabled: !_stopwatchMode
        CoverAction {
            iconSource: "image://theme/icon-cover-alarm"
            onTriggered: {
                if (mainPage) {
                    // pop until main page is on top
                    if (mainPage !== pageStack.currentPage) {
                        pageStack.pop(mainPage, PageStackAction.Immediate)
                    }
                    mainPage.reset()
                    mainPage.newAlarm(PageStackAction.Immediate)
                    mainWindow.activate()
                }
            }
        }
    }

    CoverActionList {
        enabled: _stopwatchMode
        CoverAction {
            iconSource: (stopwatch && stopwatch.running) ? "image://theme/icon-cover-pause" : "image://theme/icon-cover-play"
            onTriggered: stopwatch.running ? stopwatch.pause() : stopwatch.start()
        }
    }
}
