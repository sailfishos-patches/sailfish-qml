import QtQuick 2.0
import Sailfish.Silica 1.0

ListItem {
    id: root

    property date activeDay
    property bool menuOpen

    contentHeight: Math.max(Theme.itemSizeMedium, column.height + Theme.paddingSmall*2)

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
                allDay: model.event.allDay
                startTime: model.occurrence.startTime
                endTime: model.occurrence.endTime
                activeDay: root.activeDay
                font.pixelSize: Theme.fontSizeLarge
                color: root.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            }

            Label {
                width: root.width - 2*Theme.paddingMedium - Theme.paddingSmall - Theme.horizontalPageMargin + Theme.paddingMedium
                text: model.event.displayLabel
                font.pixelSize: Theme.fontSizeMedium
                truncationMode: TruncationMode.Fade
                color: root.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
        }
    }

    onClicked: {
        pageStack.animatorPush("EventViewPage.qml",
                               {   uniqueId: model.event.uniqueId,
                                   recurrenceId: model.event.recurrenceId,
                                   startTime: model.occurrence.startTime,
                                   'remorseParent': root
                               })
    }
}
