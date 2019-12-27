/*
 * Copyright (c) 2015 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

SilicaItem {
    id: weekDayView

    property real itemWidth: Theme.paddingSmall

    property string days: ""
    property color color: highlighted ? palette.highlightColor : palette.primaryColor

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row

        width: weekDayView.width
        height: weekDayView.height
        spacing: (width - weekDayView.itemWidth*8) / 7

        Repeater {
            model: 8

            Rectangle {
                property bool active: weekDayView.days.indexOf("mtwTf-sS"[index]) >= 0

                radius: Math.round(Theme.paddingSmall/2)
                width: weekDayView.itemWidth
                // Gap between weekdays and weekend
                color: index == 5 ? "transparent" : weekDayView.color
                opacity: index > 5 ? Theme.opacityLow : (active ? 1.0 : Theme.opacityHigh)
                height: active ? weekDayView.height : width
            }
        }
    }
}

