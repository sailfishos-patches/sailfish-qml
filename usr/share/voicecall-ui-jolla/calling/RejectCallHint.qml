import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    property alias running: touchInteractionHint.running
    signal finished

    Component.onCompleted: touchInteractionHint.start()
    Component.onDestruction: finished()
    anchors.fill: parent

    TouchInteractionHint {
        id: touchInteractionHint

        loops: 2
        direction: TouchInteraction.Up
        startY: parent.height/2 - height/2 + Theme.itemSizeSmall
        anchors.horizontalCenter: parent.horizontalCenter
        onRunningChanged: if (!running) parent.destroy(1000)
    }
}
