import QtQuick 2.0
import Sailfish.Silica 1.0

Row {
    spacing: Theme.paddingLarge
    anchors {
        top: parent.top
        topMargin: Theme.paddingLarge
        horizontalCenter: parent.horizontalCenter
    }
    Label {
        text: "Full"
        MouseArea {
            anchors { margins: -Theme.paddingMedium; fill: parent }
            onClicked: {
                parent.highlighted = !parent.highlighted
                batteryStatus.chargePercentage = parent.highlighted ? 100 : 58
            }
        }
    }
    Label {
        text: "Error"
        highlighted: batteryStatus._error
        MouseArea {
            anchors { margins: -Theme.paddingMedium; fill: parent }
            onClicked: batteryStatus._error = !batteryStatus._error
        }
    }
    Label {
        text: "Shutdown"
        highlighted: actdeadApplication.splashScreenVisible
        MouseArea {
            anchors { margins: -Theme.paddingMedium; fill: parent }
            onClicked: actdeadApplication.splashScreenVisible = !actdeadApplication.splashScreenVisible
        }
    }
}
