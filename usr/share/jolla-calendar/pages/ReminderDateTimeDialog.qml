import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: root
    property var dateTime

    Column {
        width: parent.width

        DialogHeader {}
        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * x
            //% "Select the date and time for your custom reminder"
            text: qsTrId("calendar-reminder-lbl-date_time")
            color: Theme.highlightColor
            wrapMode: Text.Wrap
        }
        Item {
            width: parent.width
            height: Theme.paddingMedium
        }
        BackgroundItem {
            height: Math.max(Theme.itemSizeMedium, dateLabel.height + 2 * Theme.paddingSmall)
            Image {
                id: dateIcon
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
                source: "image://theme/icon-m-date"
            }
            Label {
                id: dateLabel
                anchors {
                    left: dateIcon.right
                    leftMargin: Theme.paddingMedium
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
                text: Format.formatDate(root.dateTime, Format.DateFull)
                wrapMode: Text.Wrap
            }
            onClicked: {
                var obj = pageStack.animatorPush("Sailfish.Silica.DatePickerDialog",
                    {date: root.dateTime})
                obj.pageCompleted.connect(function(datePicker) {
                    datePicker.accepted.connect(function() {
                        root.dateTime = new Date(datePicker.year, datePicker.month - 1,
                            datePicker.day, root.dateTime.getHours(),
                            root.dateTime.getMinutes())
                    })
                })
            }
        }
        BackgroundItem {
            height: Theme.itemSizeMedium
            Image {
                id: timeIcon
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
                source: "image://theme/icon-m-clock"
            }
            Label {
                anchors {
                    left: timeIcon.right
                    leftMargin: Theme.paddingMedium
                    verticalCenter: parent.verticalCenter
                }
                text: Format.formatDate(root.dateTime, Format.TimeValue)
            }
            onClicked: {
                var obj = pageStack.animatorPush("Sailfish.Silica.TimePickerDialog",
                    {hour: root.dateTime.getHours(), minute: root.dateTime.getMinutes()})
                obj.pageCompleted.connect(function(timePicker) {
                    timePicker.accepted.connect(function() {
                        root.dateTime = new Date(root.dateTime.getFullYear(),
                            root.dateTime.getMonth(), root.dateTime.getDate(),
                            timePicker.hour, timePicker.minute)
                    })
                })
            }
        }
    }
}
