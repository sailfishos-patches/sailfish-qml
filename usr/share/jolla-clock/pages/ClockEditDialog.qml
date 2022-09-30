import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import com.jolla.clock.private 1.0
import "editdialog"
import "../common"

Dialog {
    id: dialog

    property bool alarmMode: true
    property bool editExisting
    property QtObject alarmObject
    property alias time: timePicker.time
    property alias second: timePicker._second
    property alias hour: timePicker.hour
    property alias minute: timePicker.minute
    property alias mode: timePicker._mode
    property string title
    property string weekDays

    readonly property bool _hoursAndMinutes: mode == TimePickerMode.HoursAndMinutes

    // don't allow saving timers with zero time
    canAccept: alarmMode || (_hoursAndMinutes ? (hour != 0 || minute != 0) : (minute != 0 || second != 0))

    onOpened: {
        if (alarmObject) {
            hour = alarmObject.hour
            minute = alarmObject.minute
            second = alarmObject.second
            title = alarmObject.title

            if (hour > 0) {
                mode = TimePickerMode.HoursAndMinutes
            } else if (second > 0) {
                mode = TimePickerMode.MinutesAndSeconds
            }

            weekDays = alarmObject.daysOfWeek
        }
    }

    onAccepted: {
        var title = dialog.title.replace(/\n/g, " ")
        if (title != "") {
            alarmObject.title = title
        } else {
            if (alarmMode) {
                //% "Alarm"
                alarmObject.title = qsTrId("clock-la-alarm")
            } else {
                //% "Timer"
                alarmObject.title = qsTrId("clock-la-timer")
            }
        }

        alarmObject.minute = minute
        if (_hoursAndMinutes) {
            alarmObject.hour = hour
            alarmObject.second = 0
        } else {
            alarmObject.hour = 0
            alarmObject.second = second
        }

        if (alarmObject.enabled) {
            Clock.cancelNotifications(alarmObject.id)
        }

        if (alarmMode) {
            alarmObject.enabled = true
            alarmObject.daysOfWeek = weekDays
            // If user does not respond to alarm, snooze 2 times, dismiss after 3rd alarm.
            alarmObject.maximalTimeoutSnoozeCount = 2
            mainPage.publishRemainingTime(hour, minute, weekDays)
        } else {
            alarmObject.enabled = false
            alarmObject.countdown = true
            // Reset alarm object in case we are editing an existing timer
            alarmObject.reset()
        }

        alarmObject.save()
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height
        flickableDirection: Flickable.VerticalFlick

        Column {
            id: column

            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                id: header
                //: Dialog accept text
                //% "Save"
                acceptText: qsTrId("clock-he-save")
                title: {
                    if (alarmMode) {
                        if (editExisting) {
                            //% "Edit alarm"
                            return qsTrId("clock-he-edit_alarm")
                        } else {
                            //% "New alarm"
                            return qsTrId("clock-he-new-alarm")
                        }
                    } else {
                        if (editExisting) {
                            //% "Edit timer"
                            return qsTrId("clock-he-edit_timer")
                        } else {
                            //% "New timer"
                            return qsTrId("clock-he-new_timer")
                        }
                    }
                }
            }
            Item {
                height: childrenRect.height
                width: parent.width
                TimePicker {
                    id: timePicker
                    x: isPortrait ? (column.width-width)/2 : Theme.horizontalPageMargin
                    // otherwise in 12h mode this caused timer 00:00 to display as 12:00am
                    hourMode: dialog.alarmMode ? DateTime.DefaultHours : DateTime.TwentyFourHours

                    Loader {
                        anchors.centerIn: parent
                        sourceComponent: alarmMode ? clockLabelComponent
                                                   : _hoursAndMinutes ? longTimerLabelComponent
                                                                      : shortTimerLabelComponent
                        Component {
                            id: clockLabelComponent
                            ClockItem {
                                primaryPixelSize: Theme.fontSizeHuge
                                color: Theme.primaryColor
                                secondaryColor: Theme.secondaryColor
                                time: timePicker.time
                            }
                        }

                        Component {
                            id: longTimerLabelComponent
                            Column {
                                spacing: -Theme.paddingMedium
                                TimeLabel {
                                    value: timePicker.hour.toLocaleString()
                                    //: "Hour abbrevation. Should be short form if possible."
                                    //% "h"
                                    label: qsTrId("clock-la-hour_short", timePicker.hour)
                                }
                                TimeLabel {
                                    value: timePicker.minute.toLocaleString()
                                    //: "Minute abbrevation. Should be short form if possible."
                                    //% "min"
                                    label: qsTrId("clock-la-minutes_short", timePicker.minute)
                                }
                            }
                        }

                        Component {
                            id: shortTimerLabelComponent
                            Column {
                                spacing: -Theme.paddingMedium
                                TimeLabel {
                                    value: timePicker.minute.toLocaleString()
                                    //: "Minute abbrevation. Should be short form if possible."
                                    //% "min"
                                    label: qsTrId("clock-la-minutes_short", timePicker.minute)
                                }
                                TimeLabel {
                                    value: timePicker._second.toLocaleString()
                                    //: "Second abbrevation. Should be short form if possible."
                                    //% "s"
                                    label: qsTrId("clock-la-seconds_very_short", timePicker._second)
                                }
                            }
                        }
                    }
                }

                Loader {
                    id: footer
                    anchors {
                        top: isPortrait ? timePicker.bottom : parent.top
                        left: isPortrait ? parent.left : timePicker.right
                        right: parent.right
                        topMargin: isPortrait ? (alarmMode ? -1 : 1) * Theme.paddingMedium : Theme.paddingMedium
                        leftMargin: isPortrait ? 0 : Theme.paddingLarge
                    }
                    sourceComponent: alarmMode ? alarmFooter : timerFooter
                }
                Component {
                    id: alarmFooter
                    Column {
                        Label {
                            x: Theme.horizontalPageMargin
                            width: parent.width - x * 2
                            color: Theme.highlightColor
                            horizontalAlignment: Qt.AlignRight
                            //: Header above days of week to repeat alarm
                            //% "Repeat"
                            text: qsTrId("clock-he-repeat_weekdays")
                        }
                        WeekDaySelector {
                            id: weekDaySelector
                            anchors {
                                left: parent.left
                                right: parent.right
                                rightMargin: isPortrait ? 0 : Theme.paddingMedium
                            }

                            weekDays: dialog.weekDays
                            Binding {
                                target: dialog
                                property: "weekDays"
                                value: weekDaySelector.weekDays
                            }
                        }
                        TextField {
                            //% "Alarm name"
                            placeholderText: qsTrId("clock-ph-alarm_name")
                            label: placeholderText
                            focusOutBehavior: FocusBehavior.KeepFocus
                            width: parent.width
                            text: dialog.title
                            EnterKey.iconSource: "image://theme/icon-m-enter-close"
                            EnterKey.onClicked: focus = false

                            onTextChanged: dialog.title = text
                        }
                    }
                }
                Component {
                    id: timerFooter
                    Column {
                        TextField {
                            //% "Timer name"
                            placeholderText: qsTrId("clock-ph-timer_name")
                            label: placeholderText
                            focusOutBehavior: FocusBehavior.KeepFocus
                            width: parent.width
                            text: dialog.title
                            EnterKey.iconSource: "image://theme/icon-m-enter-close"
                            EnterKey.onClicked: focus = false

                            onTextChanged: dialog.title = text
                        }
                        ComboBox {
                            //: Units used to pick timer interval (hours and minutes, or minutes and seconds)
                            //% "Units"
                            label: qsTrId("clock-la-units")
                            currentIndex: timePicker._mode
                            onCurrentIndexChanged: timePicker._mode = currentIndex
                            menu: ContextMenu {
                                x: 0
                                width: parent ? parent.width : Screen.width
                                MenuItem {
                                    //% "Hours and minutes"
                                    text: qsTrId("clock-me-hours_and_minutes")
                                }
                                MenuItem {
                                    //% "Minutes and seconds"
                                    text: qsTrId("clock-me-minutes_and_seconds")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
