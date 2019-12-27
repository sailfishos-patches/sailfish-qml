import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: eventItem

    width: 0 // layouting sets

    Rectangle {
        id: bar
        x: Theme.paddingMedium
        width: Theme.paddingSmall
        radius: Math.round(width/3)
        color: event.color

        anchors {
            top: parent.top
            topMargin: Theme.paddingSmall
            bottom: parent.bottom
            bottomMargin: Theme.paddingSmall
        }
    }

    Label {
        id: displayLabel
        anchors {
            left: bar.right
            leftMargin: Theme.paddingMedium
            right: parent.right
        }
        color: highlighted ? Theme.highlightColor : Theme.primaryColor
        text: event.displayLabel
        truncationMode: TruncationMode.Fade
    }

    Label {
        visible: eventItem.height >= (dayPage.cellHeight * 2)
        anchors {
            left: displayLabel.left
            right: parent.right
            top: displayLabel.bottom
            topMargin: -Math.round(Theme.paddingSmall/2)
        }
        text: event.location
        maximumLineCount: 1
        color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
        truncationMode: TruncationMode.Fade
    }

    onClicked: {
        pageStack.animatorPush("EventViewPage.qml",
                               { uniqueId: event.uniqueId,
                                   recurrenceId: event.recurrenceId,
                                   startTime: occurrence.startTime,
                                   'remorseParent': eventItem
                               })

    }
    onPressAndHold: {
        var coord = mapToItem(flickable.contentItem, mouse.x, mouse.y)
        dayPage.timePressAndHold(coord.x, coord.y)
    }
}
