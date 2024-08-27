import QtQuick 2.0
import Sailfish.Silica 1.0
import Calendar.daylightSavingTime 1.0

Column {
    id: root
    property alias referenceDateTime: dst.referenceDateTime
    property real textVerticalCenterOffset: text.y + text.height / 2 - height / 2
    property string transitionDescription

    property int transitionTime: -1
    property int transitionDay: -1
    property int transitionMonth: -1
    property int transitionYear: -1
    states: State {
        when: dst.nextDaylightSavingTime
              && !isNaN(dst.nextDaylightSavingTime.getTime())
        PropertyChanges {
            target: root
            transitionTime: dst.nextDaylightSavingTime.getHours()
            transitionDay: dst.nextDaylightSavingTime.getDate()
            transitionMonth: dst.nextDaylightSavingTime.getMonth()
            transitionYear: dst.nextDaylightSavingTime.getFullYear()
            transitionDescription: {
                var beforeDST = dst.nextDaylightSavingTime
                beforeDST.setDate(beforeDST.getDate() - 1)
                beforeDST.setTime(beforeDST.getTime() - dst.daylightSavingOffset * 1000)
                // We just need the time here. But the time of DST will be the
                // new time after change, while we need the time before change.
                // We work with the day before DST to be able to get the time
                // at the moment of the DST. This time does not exist at the DST day.
                var timeStr = Format.formatDate(beforeDST, Formatter.TimeValue)
                var hourShift = dst.daylightSavingOffset / 3600
                if (dst.daylightSavingOffset < 0) {
                    //: in most cases %n == 1 and can be translated like 'an hour backward'
                    //% "At %1, clocks are turned backward %n hour."
                    return qsTrId("sailfish-calendar_la_dst-move-backward", -hourShift).arg(timeStr)
                } else {
                    //: in most cases %n == 1 and can be translated like 'an hour forward'
                    //% "At %1, clocks are turned forward %n hour."
                    return qsTrId("sailfish-calendar_la_dst-move-forward", hourShift).arg(timeStr)
                }
            }
        }
    }

    property int _margin: Theme.paddingSmall / 2

    width: implicitWidth + 2 * _margin
    spacing: -_margin

    Icon {
        x: root._margin
        source: "image://theme/icon-s-time"
        color: Theme.secondaryHighlightColor
        width: text.width
        fillMode: Image.PreserveAspectFit
    }
    Label {
        id: text
        x: root._margin
        font.pixelSize: Theme.fontSizeTinyBase
        text: {
            if (dst.daylightSavingOffset < 0) {
                return "-" + (-dst.daylightSavingOffset / 3600)
            } else {
                return "+" + (dst.daylightSavingOffset / 3600)
            }
        }
        color: Theme.secondaryHighlightColor
    }

    DaylightSavingTime {
        id: dst
    }
}
