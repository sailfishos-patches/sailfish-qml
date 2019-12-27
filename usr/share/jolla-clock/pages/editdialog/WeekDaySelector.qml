import QtQuick 2.0
import Sailfish.Silica 1.0

Row {
    id: buttonRow

    property string weekDays

    Repeater {
        // This should be replaced by a proper list from mlocale or qlocale,
        // once we have a wrapper for those.
        Component.onCompleted: {
            var days = "mtwTfsS"
            var result = [ ]
            var dt = new Date(2012, 0, 2)   // Jan 2, 2012 is a Monday

            for (var i=0; i<7; i++) {
                result.push({ text: Qt.formatDateTime(dt, "ddd"), day: days[i] })
                dt.setDate(dt.getDate() + 1)
            }
            model = result
        }

        MouseArea {
            property bool down: pressed && containsMouse

            height: childrenRect.height + Theme.paddingLarge
            width: buttonRow.width / 7

            onClicked: button.checked = !button.checked

            Switch {
                id: button

                width: parent.width
                down: parent.down || pressed && containsMouse
                checked: weekDays.indexOf(modelData.day) >= 0

                onCheckedChanged: {
                    if (checked) {
                        if (weekDays.indexOf(modelData.day) < 0)
                            weekDays += modelData.day
                    } else {
                        var re = ""
                        for (var i = 0; i < weekDays.length; i++) {
                            if (weekDays[i] != modelData.day)
                                re += weekDays[i]
                        }
                        weekDays = re
                    }
                }
            }

            Label {
                id: buttonText
                anchors {
                    horizontalCenter: button.horizontalCenter
                    top: button.bottom
                    topMargin: -Theme.paddingLarge
                }
                text: modelData.text
                color: button.down ? Theme.highlightColor : Theme.primaryColor
                font.pixelSize: Theme.fontSizeSmall
            }
        }
    }
}
