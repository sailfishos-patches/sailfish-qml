import QtQuick 2.0
import Sailfish.Silica 1.0

GridItem {
    id: alarmItemBase

    property QtObject alarm: model.alarm
    property bool showContents: true
    property real scaleRatio: Math.min(1.2, Screen.width/Theme.pixelRatio/540)

    highlighted: alarm.enabled || down || menuOpen

    function remove() {
        showContents = false
        alarm.deleteAlarm()
    }

    width: Theme.itemSizeHuge
    _backgroundColor: "transparent"
}
