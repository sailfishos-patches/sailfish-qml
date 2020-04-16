/**
 * Copyright (c) 2012 - 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.notifications 1.0
import "../common/DateUtils.js" as DateUtils

Page {
    id: root

    property int placeholderY: Math.round(height/4)

    function reset(index, operationType) {
        tabs.moveTo(1, TabViewAction.Immediate)
    }

    function newTimer(operationType) {
        pageStack.animatorPush(Qt.resolvedUrl("ClockEditDialog.qml"),
                       { alarmObject: timersModel.createAlarm(), alarmMode: false, editExisting: false }, operationType)
    }

    function newAlarm(operationType) {
        pageStack.animatorPush(Qt.resolvedUrl("ClockEditDialog.qml"),
                       { alarmObject: alarmsModel.createAlarm(), alarmMode: true, editExisting: false }, operationType)
    }

    function publishRemainingTime(hour, minute, weekDays) {
        var time = DateUtils.remainingTime(hour, minute, weekDays)
        var days = DateUtils.days(time)
        var hours = DateUtils.hours(time)
        var minutes = DateUtils.minutes(time)

        //: E.g. "1 day" or "4 days", used in a sentence like "Expiring in 1 day, 2 hours and 3 minutes"
        //% "%0 day(s)"
        var daysText = qsTrId("clock-la-days", days).arg(days)

        //: E.g. "1 hour", "3 hours", used in a sentence like "Expiring in 1 hours and 2 minutes"
        //% "%0 hour(s)"
        var hoursText = qsTrId("clock-la-hours", hours).arg(hours)

        //: E.g. "1 minute", "15 minutes", used in a sentence like "Expiring in 4 days, 12 hours and 30 minutes"
        //% "%0 minute(s)"
        var minutesText = qsTrId("clock-la-minutes", minutes).arg(minutes)

        if (days > 0) {
            //: E.g. Expiring in 2 days, 3 hours and 1 minute, time measurements are localized separately
            //% "Expiring in %0, %1 and %2"
            notification.previewBody =
                    qsTrId("clock-la-expiring_in_days_hours_minutes").arg(daysText).arg(hoursText).arg(minutesText)
        } else if (hours > 0) {
            //: E.g. Expiring in 1 hour and 13 minutes, time measurements are localized separately
            //% "Expiring in %0 and %1"
            notification.previewBody = qsTrId("clock-la-expiring_in_hours_minutes").arg(hoursText).arg(minutesText)
        } else {
            //: E.g. Expiring in 26 minutes, time measurements are localized separately
            //% "Expiring in %0"
            notification.previewBody = qsTrId("clock-la-expiring_in_minutes").arg(minutesText)
        }
        notification.publish()
    }

    Notification {
        id: notification

        icon: "icon-system-alarm"
        isTransient: true
    }

    Component.onCompleted: mainPage = root
    clip: true

    TabView {
        id: tabs

        anchors.fill: parent
        currentIndex: 1

        header: TabButtonRow {
            Repeater {
                model: [
                    //: Title of Timers tab page showing saved timers
                    //% "Timers"
                    qsTrId("clock-he-timers"),
                    //: Title of Alarms tab page showing saved alarms
                    //% "Alarms"
                    qsTrId("clock-he-alarms"),
                    //: Title of Stopwatch tab page with stopwatch counter
                    //% "Stopwatch"
                    qsTrId("clock-he-stopwatch"),
                ]

                TabButton {
                    onClicked: tabs.moveTo(model.index)

                    title: modelData
                    tabIndex: model.index
                }
            }
        }

        model: [timerView, alarmView, stopwatchView]
        Component {
            id: timerView
            TimerView {
                topMargin: tabs.headerHeight
            }
        }
        Component {
            id: alarmView
            AlarmView {
                topMargin: tabs.headerHeight
            }
        }
        Component {
            id: stopwatchView
            TabItem {
                allowDeletion: false
                StopwatchView {}
            }
        }
    }
}
