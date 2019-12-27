/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import org.nemomobile.time 1.0
import org.nemomobile.lipstick 0.1
import "../main"

Item {
    id: clock

    property alias time: timeText.time
    property alias color: timeText.color
    property bool followPeekPosition
    property alias updatesEnabled: timeText.updatesEnabled
    readonly property bool largeScreen: Screen.sizeCategory >= Screen.Large
    readonly property alias weekdayFont: weekday.font

    width: Math.max(timeText.width, weekday.width, month.width)
    height: timeText.font.pixelSize + weekday.font.pixelSize + month.font.pixelSize + Theme.paddingMedium
    baselineOffset: timeText.y + timeText.baselineOffset

    ClockItem {
        id: timeText
        color: Theme.primaryColor
        // Ascender of the time to the top of the clock.
        anchors {
            bottom: parent.top
            bottomMargin: -timeText.font.pixelSize
            horizontalCenter: parent.horizontalCenter
        }
        font { pixelSize: largeScreen ? Theme.fontSizeHuge * 2.0 : Math.round(128 * Screen.widthRatio); family: Theme.fontFamilyHeading }
    }

    Connections {
        target: Lipstick.compositor
        onDisplayAboutToBeOn: timeText.forceUpdate()
    }

    Text {
        id: weekday
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: timeText.baseline
            topMargin: Theme.paddingMedium
        }
        color: timeText.color
        font { pixelSize: largeScreen ? Theme.fontSizeLarge : Math.round(40 * Screen.widthRatio); family: Theme.fontFamily }
        text: {
            var day = Format.formatDate(time, Format.WeekdayNameStandalone)
            return day[0].toUpperCase() + day.substring(1)
        }
    }

    Text {
        id: month
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: weekday.baseline
            topMargin: Theme.paddingMedium
        }
        color: timeText.color
        font { pixelSize: largeScreen ? Theme.fontSizeExtraLarge * 1.1 : Math.round(55 * Screen.widthRatio); family: Theme.fontFamily }

        text: Format.formatDate(time, Format.DateMediumWithoutYear)
    }
}
