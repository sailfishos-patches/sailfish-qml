/****************************************************************************
**
** Copyright (C) 2017 Jolla Ltd.
** Contact: Chris Adams <chris.adams@jolla.com>
**
****************************************************************************/

import QtQuick 2.4
import Sailfish.Silica 1.0
import org.nemomobile.calendar.lightweight 1.0
import Sailfish.Calendar 1.0

BackgroundItem {
    id: delegate

    property int pixelSize              // the size of the font used for date/time labels
    property real maxTimeLabelWidth     // calculated via font metrics on long day names / time strings
    property real labelLeftMargin       // the margin to use, left of the date/time labels
    property bool isToday               // whether the date of the event is today

    property real timeWidth: timeLabel.implicitWidth
    property string dateLabel: {
        if (isToday) {
            //% "Today"
            return qsTrId("sailfish_calendar-la-today")
        } else {
            var weekday = Format.formatDate(startTime, Formatter.WeekdayNameStandalone)
            return weekday.charAt(0).toUpperCase() + weekday.substr(1)
        }
    }

    width: parent.width
    height: row.height + 2*Theme.paddingMedium

    Row {
        id: row
        x: labelLeftMargin
        width: parent.width - x
        spacing: Theme.paddingSmall
        anchors.verticalCenter: parent.verticalCenter
        Label {
            id: timeLabel

            width: Math.max(maxTimeLabelWidth, implicitWidth)
            color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            font.pixelSize: delegate.pixelSize
            font.strikeout: cancelled
            //% "All day"
            text: allDay ? qsTrId("sailfish_calendar-la-all_day")
                         : Format.formatDate(startTime, Formatter.TimeValue)
        }

        CalendarColorBar {
            id: colorBar
            color: model.color
            height: Math.max(timeLabel.height, nameLabel.height)
        }

        Label {
            id: nameLabel

            width: parent.width - timeLabel.width - colorBar.width - 2*parent.spacing

            color: highlighted ? Theme.highlightColor : Theme.primaryColor
            text: CalendarTexts.ensureEventTitle(displayLabel)
            truncationMode: TruncationMode.Fade
            font.pixelSize: delegate.pixelSize
        }
    }
}
