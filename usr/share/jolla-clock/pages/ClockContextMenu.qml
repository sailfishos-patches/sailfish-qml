import QtQuick 2.0
import Sailfish.Silica 1.0

ContextMenu {
    property Item item
    readonly property QtObject alarm: item.alarm
    onAlarmChanged: if (alarm) resetItem.visible = alarm.triggerTime > 0 || alarm.elapsed > 0

    MenuItem {
        id: resetItem
        //% "Reset"
        text: qsTrId("clock-me-reset")
        onClicked: {
            alarm.enabled = false
            alarm.reset()
            alarm.save()
            if (alarm.countdown) {
                item.reset()
            }
        }
    }
    MenuItem {
        //% "Edit"
        text: qsTrId("clock-me-edit")
        onClicked: {
            pageStack.animatorPush(Qt.resolvedUrl("ClockEditDialog.qml"), {
                                       alarmMode: !alarm.countdown,
                                       alarmObject: alarm,
                                       editExisting: true
                                   })
        }
    }
    MenuItem {
        //% "Delete"
        text: qsTrId("clock-me-delete")
        onDelayedClick: item.remove()
    }
}
