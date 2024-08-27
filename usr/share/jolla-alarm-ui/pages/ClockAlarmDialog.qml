import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.alarmui 1.0
import Nemo.Time 1.0

AlarmDialogBase {
    onTimeout: closeDialog(AlarmDialogStatus.Closed)

    topIconSource: "image://theme/icon-l-snooze?" + Theme.highlightColor

    PullDownMenu {
        quickSelect: true
        bottomMargin: Theme.itemSizeExtraSmall
        MenuItem {
            //% "Snooze"
            text: qsTrId("alarm-ui-me-alarm_dialog_snooze")
            onClicked: closeDialog(AlarmDialogStatus.Snoozed)
        }
    }

    Label {
        anchors { left: parent.left; right: parent.right }
        color: Theme.primaryColor
        font {
            pixelSize: Theme.fontSizeHuge
            family: Theme.fontFamilyHeading
        }
        horizontalAlignment: Text.AlignHCenter
        maximumLineCount: 4
        text: alarm.title
        wrapMode: Text.Wrap
    }

    Label {
        id: alarmTime

        anchors { left: parent.left; right: parent.right }
        color: currentTime.visible ? Theme.secondaryColor : Theme.primaryColor
        font {
            pixelSize: Theme.fontSizeLarge
            family: Theme.fontFamilyHeading
        }

        horizontalAlignment: Text.AlignHCenter
        text: {
            var date = new Date()
            date.setHours(alarm.hour)
            date.setMinutes(alarm.minute)
            Format.formatDate(date, Formatter.TimeValue)
        }
        Behavior on color { ColorAnimation { } }
    }

    Label {
        id: currentTime

        anchors { left: parent.left; right: parent.right }
        font {
            pixelSize: Theme.fontSizeLarge
            family: Theme.fontFamilyHeading
        }
        horizontalAlignment: Text.AlignHCenter
        text: Format.formatDate(clock.time, Formatter.TimeValue)
        opacity: text === alarmTime.text ? 0.0 : 1.0
        visible: opacity > 0.0

        Behavior on opacity { FadeAnimation {} }

        WallClock {
            id: clock
            updateFrequency: WallClock.Minute
        }
    }

}
