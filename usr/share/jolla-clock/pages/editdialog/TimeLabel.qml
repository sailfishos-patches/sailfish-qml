import QtQuick 2.0
import Sailfish.Silica 1.0

Row {
    property alias value: valueLabel.text
    property alias label: labelLabel.text

    //: Can have two values: "LTR" if remaining time in timer item should be written in "[value] [unit]" order i.e. "2 min", or "RTL" i.e. right-to-left like in Arabic writing systems
    //% "LTR"
    property bool leftToRight: qsTrId("clock-la-timer_writing_direction") !== "RTL"

    spacing: Theme.paddingSmall
    anchors.horizontalCenter: parent.horizontalCenter
    layoutDirection: leftToRight ? Qt.LeftToRight : Qt.RightToLeft

    Label {
        id: valueLabel
        font.pixelSize: Theme.fontSizeHuge
        height: Math.min(implicitHeight, (timePicker.height*0.4 + Theme.paddingMedium)/2)
        fontSizeMode: Text.VerticalFit
    }
    Label {
        id: labelLabel
        anchors.baseline: valueLabel.baseline
        color: Theme.secondaryColor
    }
}

