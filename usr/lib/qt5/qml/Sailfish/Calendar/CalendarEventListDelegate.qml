import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0
import Sailfish.Calendar 1.0

ListItem {
    id: root

    property alias timeText: timeLabel.text
    property alias activeDay: timeLabel.activeDay

    contentHeight: Math.max(Theme.itemSizeMedium, column.height + 2*Theme.paddingMedium)

    Row {
        height: column.height
        anchors.verticalCenter: parent.verticalCenter
        x: isLandscape ? Theme.paddingLarge : (Screen.sizeCategory > Screen.Medium ? Theme.horizontalPageMargin : Theme.paddingMedium)
        spacing: Theme.paddingMedium

        Rectangle {
            width: Theme.paddingSmall
            radius: Math.round(width/3)
            color: model.event.color
            height: parent.height
        }

        Column {
            id: column

            spacing: -Theme.paddingSmall
            anchors.verticalCenter: parent.verticalCenter
            EventTimeLabel {
                id: timeLabel
                allDay: model.event.allDay
                startTime: model.occurrence.startTime
                endTime: model.occurrence.endTime
                font.pixelSize: Theme.fontSizeLarge
                font.strikeout: model.event.status == CalendarEvent.StatusCancelled
                color: root.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            }

            Label {
                id: displayLabel
                width: root.width - 2*Theme.paddingMedium - Theme.paddingSmall - Theme.horizontalPageMargin + Theme.paddingMedium
                text: CalendarTexts.ensureEventTitle(model.event.displayLabel)
                font.pixelSize: Theme.fontSizeMedium
                truncationMode: TruncationMode.Fade
                color: root.highlighted ? Theme.highlightColor : Theme.primaryColor
            }

            SyncWarningItem {
                width: displayLabel.width
                visible: model.event.syncFailure != CalendarEvent.NoSyncFailure
                syncFailure: model.event.syncFailure
                highlighted: root.highlighted
                color: root.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            }
        }
    }
}
