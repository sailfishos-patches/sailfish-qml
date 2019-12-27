/*
 * Copyright (c) 2015 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

SilicaItem {
    id: alarmItem

    property QtObject alarm: model

    width: Theme.itemSizeHuge
    height: column.height + 2*Theme.paddingMedium

    Column {
        id: column
        width: parent.width -2*Theme.paddingMedium
        spacing: -Theme.paddingSmall
        anchors.centerIn: parent
        Behavior on opacity { FadeAnimation {} }

        Row {
            id: row
            Item {
                id: indicator
                width: Theme.itemSizeSmall/2
                height: Theme.itemSizeSmall/2
                anchors.verticalCenter: parent.verticalCenter
                GlassItem {
                    anchors.centerIn: parent
                    color: highlighted ? palette.highlightColor : palette.primaryColor
                    dimmed: !alarm.enabled
                    falloffRadius: dimmed ? 0.075 : undefined
                }
            }
            Label {
                id: nameText
                anchors.verticalCenter: parent.verticalCenter
                width: column.width - indicator.width - Theme.paddingSmall
                opacity: alarmItem.highlighted ? 1.0 : Theme.opacityHigh
                text: alarm.title
                font { pixelSize: Theme.fontSizeSmall; family: Theme.fontFamilyHeading }
                truncationMode: TruncationMode.Fade
            }
        }
        ClockItem {
            id: timeText
            anchors.horizontalCenter: parent.horizontalCenter
            primaryPixelSize: Theme.fontSizeHuge
            time: {
                var date = new Date()
                date.setHours(alarm.hour)
                date.setMinutes(alarm.minute)
                return date
            }
        }
        Item {
            width: parent.width
            height: Theme.paddingMedium + Theme.paddingSmall
        }
        WeekDayView {
            id: weekdays
            anchors {
                left: parent.left
                leftMargin: Theme.paddingMedium
                right: parent.right
                rightMargin: Theme.paddingMedium
            }
            days: alarm.daysOfWeek
            height: Theme.paddingMedium + Theme.paddingSmall
            opacity: alarm.daysOfWeek !== "" ? 1.0 : 0.0
        }
        Item {
            width: parent.width
            height: Theme.paddingSmall
        }
    }
}

