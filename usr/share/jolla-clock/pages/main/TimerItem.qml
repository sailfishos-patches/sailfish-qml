import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.clock.private 1.0
import "../../common"

AlarmItemBase {
    id: timerItem

    contentHeight: column.height + 2*Theme.paddingMedium

    function reset() {
        clock.reset()
    }

    onClicked: {
        alarm.enabled = !alarm.enabled
        alarm.save()
    }

    Column {
        id: column
        y: Theme.paddingMedium
        spacing: Theme.paddingSmall
        opacity: showContents ? 1.0 : 0.0
        Behavior on opacity { FadeAnimation {} }
        anchors {
            horizontalCenter: parent.horizontalCenter
            horizontalCenterOffset: model.index % columnCount === 0 ? Theme.paddingSmall
                                                          :  model.index % columnCount === (columnCount-1) ? -Theme.paddingSmall
                                                                                   : 0
        }
        width: parent.width-Theme.paddingLarge-Theme.paddingSmall
        TimerCircle {
            id: circle

            //: Can have two values: "LTR" if remaining time in timer item should be written in "[value] [unit]" order i.e. "2 min", or "RTL" i.e. right-to-left like in Arabic writing systems
            //% "LTR"
            property bool leftToRight: qsTrId("clock-la-timer_writing_direction") !== "RTL"
            width: parent.width
            height: width
            color: timerItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            elapsedColor: timerItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            elapsedOpacity: Theme.opacityFaint
            smooth: true
            value: clock.progress

            TimerClock {
                id: clock
                keepRunning: Qt.application.active
            }

            Column {
                anchors.centerIn: circle
                Row {
                    spacing: Theme.paddingSmall
                    visible: minutes.value !== 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    layoutDirection: circle.leftToRight ? Qt.LeftToRight : Qt.RightToLeft
                    Label {
                        id: minutes
                        property int value: Math.floor(clock.remaining / 60)

                        text: value.toLocaleString()
                        color: timerItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                        font.pixelSize: Theme.fontSizeLarge
                        width: Math.min(implicitWidth, circle.width*0.8 - minutesLabel.width - parent.spacing)
                        // QTBUG-55873: Workaround for implicitHeight not getting updated
                        verticalAlignment: Text.AlignBottom
                        height: implicitHeight
                        fontSizeMode: Text.HorizontalFit
                    }
                    Label {
                        id: minutesLabel
                        //% "min"
                        text: qsTrId("clock-la-minute_short", minutes.value)
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.baseline: minutes.baseline
                        verticalAlignment: Text.AlignBottom
                        color: timerItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    }
                }

                Row {
                    spacing: Theme.paddingSmall
                    visible: seconds.value !== 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    layoutDirection: circle.leftToRight ? Qt.LeftToRight : Qt.RightToLeft
                    Label {
                        id: seconds
                        property int value: clock.remaining % 60

                        text: value.toLocaleString()
                        color: timerItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                        font.pixelSize: Theme.fontSizeLarge
                        width: Math.min(implicitWidth, circle.width*0.8 - secondLabel.width - parent.spacing)
                        // QTBUG-55873: Workaround for implicitHeight not getting updated
                        verticalAlignment: Text.AlignBottom
                        fontSizeMode: Text.HorizontalFit
                        height: implicitHeight
                    }
                    Label {
                        id: secondLabel
                        // Abbreviated second to fit inside the timer circle
                        //% "sec"
                        text: qsTrId("clock-la-seconds_short", seconds.value)
                        font.pixelSize: Theme.fontSizeExtraSmall
                        anchors.baseline: seconds.baseline
                        verticalAlignment: Text.AlignBottom
                        color: timerItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    }
                }
            }
        }

        Label {
            width: parent.width
            color: timerItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            horizontalAlignment: implicitWidth > width ? Qt.AlignLeft : Qt.AlignHCenter
            font.pixelSize: Theme.fontSizeSmall // For consistency with AlarmItem
            text: alarm.title
            truncationMode: TruncationMode.Fade
            maximumLineCount: 1
        }
    }
}
