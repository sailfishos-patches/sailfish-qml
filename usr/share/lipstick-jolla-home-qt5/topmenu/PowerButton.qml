import QtQuick 2.2
import Sailfish.Silica 1.0

MouseArea {
    id: button

    property url iconSource
    property alias icon: icon
    readonly property bool down: (pressed && containsMouse) || pressTimer.running

    property alias offset: content.y

    objectName: "PowerButton"

    PauseAnimation {
        id: pressTimer
        alwaysRunToEnd: true
        running: button.pressed
        duration: 50
    }

    Item {
        id: content

        width: button.width
        height: button.height

        Image {
            id: icon

            anchors.centerIn: parent

            source: button.down
                    ? button.iconSource + "?" + Theme.highlightColor
                    : button.iconSource

            width: Theme.iconSizeLauncher
            height: Theme.iconSizeLauncher
        }
    }
}
