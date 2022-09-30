import QtQuick 2.6
import Sailfish.Silica 1.0
import com.jolla.clock.private 1.0
import "../../common"

AlarmItemBase {
    id: alarmItem

    property alias primaryPixelSize: timeText.primaryPixelSize
    property alias secondaryPixelSize: timeText.secondaryPixelSize

    contentHeight: column.height + 2*Theme.paddingMedium

    onClicked: {
        if (alarm.enabled) {
            Clock.cancelNotifications(alarm.id)
        }

        alarm.enabled = !alarm.enabled
        alarm.save()

        if (alarm.enabled) {
            mainPage.publishRemainingTime(alarm.hour, alarm.minute, alarm.daysOfWeek)
        }
    }

    Column {
        id: column
        width: parent.width -2*Theme.paddingMedium
        bottomPadding: Theme.paddingSmall
        spacing: -Theme.paddingSmall
        anchors.centerIn: parent
        opacity: showContents ? 1.0 : 0.0
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
                    color: alarmItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                    dimmed: !alarm.enabled
                    falloffRadius: dimmed ? 0.075 : undefined
                }
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                width: column.width - indicator.width - Theme.paddingSmall
                color: alarmItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                opacity: alarmItem.highlighted ? 1.0 : Theme.opacityHigh
                text: alarm.title
                font { pixelSize: scaleRatio * Theme.fontSizeSmall; family: Theme.fontFamilyHeading }
                truncationMode: TruncationMode.Fade
                maximumLineCount: 1
            }
        }

        ClockItem {
            id: timeText
            anchors.horizontalCenter: parent.horizontalCenter
            primaryPixelSize: scaleRatio * ((timeFormatConfig.value !== "24") ? Theme.fontSizeExtraLarge : Theme.fontSizeHugeBase)
            secondaryPixelSize: scaleRatio * Theme.fontSizeHuge/2.5
            color: alarmItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            secondaryColor: alarmItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
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
            color: alarmItem.highlighted ? Theme.highlightColor : Theme.primaryColor
        }
    }
}
