import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Time 1.0
import "../../common"

ClockItem {
    property alias enabled: wallClock.enabled
    anchors.horizontalCenter: parent.horizontalCenter
    time: wallClock.time
    primaryPixelSize: Screen.width/4

    WallClock {
        id: wallClock
        updateFrequency: WallClock.Minute
    }
}
