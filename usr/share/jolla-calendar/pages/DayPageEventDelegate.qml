import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0
import Sailfish.Calendar 1.0

BackgroundItem {
    id: eventItem
    property alias fontSize: displayLabel.font.pixelSize
    property bool oneLiner: true

    width: 0 // layouting sets

    Rectangle {
        id: bar
        x: oneLiner ? Theme.paddingMedium : Theme.paddingSmall
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
            leftMargin: oneLiner ? Theme.paddingMedium : Theme.paddingSmall
            right: parent.right
        }
        visible: width > 0
        color: highlighted ? Theme.highlightColor : Theme.primaryColor
        text: CalendarTexts.ensureEventTitle(event.displayLabel)
        opacity: event.status == CalendarEvent.StatusCancelled ? Theme.opacityHigh : 1.
        truncationMode: oneLiner ? TruncationMode.Fade : TruncationMode.None
        wrapMode: oneLiner ? Text.NoWrap : Text.Wrap
        clip: !oneLiner
        height: oneLiner ? implicitHeight : Math.min(parent.height, implicitHeight)
    }
    OpacityRampEffect {
        enabled: displayLabel.implicitHeight > displayLabel.height
        direction: OpacityRamp.TopToBottom
        sourceItem: displayLabel
        slope: Math.max(1, displayLabel.height / Theme.paddingLarge)
        offset: 1 - 1 / slope
    }

    Label {
        visible: eventItem.height >= (displayLabel.height + implicitHeight)
        anchors {
            left: displayLabel.left
            right: parent.right
            top: displayLabel.bottom
            topMargin: -Math.round(Theme.paddingSmall/2)
        }
        font.pixelSize: displayLabel.font.pixelSize
        //% "The event is cancelled."
        text: event.status == CalendarEvent.StatusCancelled ? qsTrId("calendar-la-event_cancelled") : event.location
        maximumLineCount: 1
        color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
        truncationMode: TruncationMode.Fade
    }

    onClicked: {
        pageStack.animatorPush("EventViewPage.qml",
                               { instanceId: event.instanceId,
                                 startTime: occurrence.startTime,
                                 'remorseParent': eventItem
                               })

    }
}
