import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.alarms 1.0
import com.jolla.alarmui 1.0
import org.nemomobile.dbus 2.0 as NemoDBus
import "pages"

ApplicationWindow {
    id: mainWindow

    allowedOrientations: Screen.sizeCategory > Screen.Medium
                         ? defaultAllowedOrientations
                         : defaultAllowedOrientations & Orientation.PortraitMask
    _defaultPageOrientations: Orientation.All
    _defaultLabelFormat: Text.PlainText
    cover: undefined
    initialPage: Component {
        Page {
            id: page

            // TODO: maybe change to ApplicationWindow.applicationActive when JB#7328 get resolved
            property bool applicationActive: Qt.application.active
            property QtObject nextAlarm // only changed by timed
            property QtObject displayedAlarm
            property Item currentDialog
            property var types: [Alarm.Calendar, Alarm.Clock, Alarm.Countdown, Alarm.Reminder]
            property bool closing // Indicates that the window is about to be destroyed

            function handleNextAlarm() {
                if (closing || !nextAlarm || page.types.indexOf(nextAlarm.type) == -1) {
                    deactivate()
                    alarmHandler.dialogOnScreen = false
                    if (closing) {
                        Qt.quit() // Window (about to be) destroyed, close immediatedly
                    } else {
                        quitTimer.start() // Wait 1000 ms for new alarms
                    }

                    return
                }

                if (quitTimer.running) {
                    quitTimer.stop()
                }

                displayedAlarm = nextAlarm
                nextAlarm = null

                if (displayedAlarm.type === Alarm.Calendar) {
                    currentDialog = calendarDialog
                } else if (displayedAlarm.type === Alarm.Clock) {
                    currentDialog = alarmDialog
                } else if (displayedAlarm.type === Alarm.Countdown) {
                    currentDialog = timerDialog
                } else if (displayedAlarm.type === Alarm.Reminder) {
                    currentDialog = reminderDialog
                }

                currentDialog.z = 1
                currentDialog.show(displayedAlarm)
                alarmHandler.dialogOnScreen = true

                // Bring to foreground
                if (!applicationActive) {
                    activate()
                }
            }

            function dialogHidden(status) {
                switch(status) {
                case AlarmDialogStatus.Dismissed:
                    displayedAlarm.dismiss()
                    break
                case AlarmDialogStatus.Snoozed:
                    displayedAlarm.snooze()
                    break
                case AlarmDialogStatus.Closed:
                    if (!displayedAlarm.maximalTimeoutSnoozeCount) {
                        // The alarm has no limit for snoozes, dismiss it on first automatic close
                        publishMissedNotification()
                        displayedAlarm.dismiss()
                        break
                    }
                    if (displayedAlarm.timeoutSnoozeCounter === displayedAlarm.maximalTimeoutSnoozeCount) {
                        // This will be the last automatic close, the alarm will be dismissed,
                        // publish a notification to let the user know about the missed alarm.
                        publishMissedNotification()
                    }
                    displayedAlarm.close()
                    break
                case AlarmDialogStatus.Invalid:
                    break
                default:
                    console.log("jolla-alarm-ui, dialogHidden(): bad parameter: ", status)
                    break
                }

                if (currentDialog) {
                    currentDialog.z = 0
                }
                displayedAlarm = null
                handleNextAlarm()
            }

            function publishMissedNotification() {
                var date = new Date
                if (displayedAlarm.type === Alarm.Clock) {
                    date.setHours(displayedAlarm.hour)
                    date.setMinutes(displayedAlarm.minute)
                    date.setSeconds(0)
                    notificationManager.publishMissedClockNotification(date, displayedAlarm.title)
                } else if (displayedAlarm.type === Alarm.Calendar) {
                    var occurrence = displayedAlarm.startDate
                    notificationManager.publishMissedCalendarNotification(occurrence, displayedAlarm.calendarEventUid,
                                                                          displayedAlarm.calendarEventRecurrenceId,
                                                                          Qt.formatDateTime(occurrence, Qt.ISODate),
                                                                          displayedAlarm.title)
                }
            }

            function closedByGesture() {
                if (displayedAlarm) {
                    currentDialog.hideImmediatedly()
                    // Dismiss a timer alarm, snooze a clock alarm
                    if (displayedAlarm.countdown) {
                        dialogHidden(AlarmDialogStatus.Dismissed)
                    } else {
                        dialogHidden(AlarmDialogStatus.Snoozed)
                    }
                }
            }

            // User swiped dialog away
            onApplicationActiveChanged: if (!applicationActive) closedByGesture()

            // User used the close gesture
            Connections {
                target: mainWindow.__quickWindow
                onClosing: {
                    page.closing = true
                    closedByGesture()
                }
            }

            Timer {
                id: quitTimer

                interval: 1000
                onTriggered: {
                    if (calendarDialog.waitingForDBusResponse) {
                        quitTimer.restart()
                    } else {
                        Qt.quit()
                    }
                }
            }

            AlarmHandler {
                id: alarmHandler

                onActiveDialogsChanged: {
                    if (activeDialogs.length > 0) {
                        if (displayedAlarm && displayedAlarm.id === activeDialogs[0].id) {
                            return
                        }

                        if (activeDialogs[0].type === Alarm.Calendar
                            && !calendarState.calendarActive(activeDialogs[0].notebookUid)) {
                            activeDialogs[0].dismiss()
                            return
                        }

                        nextAlarm = activeDialogs[0]
                        if (!displayedAlarm) {
                            handleNextAlarm()
                        } else {
                            currentDialog.hide()
                        }
                    } else {
                        // There are no active dialogs, clear displayed dialog if any
                        if (currentDialog) {
                            currentDialog.hide()
                        }
                    }
                }

                onError: {
                    console.log("jolla-alarm-ui: AlarmHandler error, message: ", message)
                }
            }

            NemoDBus.DBusInterface {
                bus: NemoDBus.DBus.SystemBus
                service: 'com.nokia.mce'
                path: '/com/nokia/mce/signal'
                iface: 'com.nokia.mce.signal'
                signalsEnabled: true

                function alarm_ui_feedback_ind(event) {
                    if (!page.displayedAlarm || !page.currentDialog || page.currentDialog.animating) {
                        return
                    }

                    if (event == "powerkey" || event == "flipover") {
                        if (page.displayedAlarm.type === Alarm.Countdown || page.displayedAlarm.type === Alarm.Reminder) {
                            page.currentDialog.closeDialog(AlarmDialogStatus.Dismissed)
                        } else {
                            page.currentDialog.closeDialog(AlarmDialogStatus.Snoozed)
                        }
                    }
                }
            }

            Loader {
                anchors.fill: parent
                source: mode === "actdead" ? Qt.resolvedUrl("pages/ActDeadWallpaper.qml") : ""
            }

            ClockAlarmDialog {
                id: alarmDialog

                anchors.fill: parent
                opacity: 0.0
                onDialogHidden: page.dialogHidden(status)
            }

            TimerAlarmDialog {
                id: timerDialog

                anchors.fill: parent
                opacity: 0.0
                onDialogHidden: page.dialogHidden(status)
            }

            CalendarAlarmDialog {
                id: calendarDialog

                anchors.fill: parent
                opacity: 0.0
                onDialogHidden: page.dialogHidden(status)
            }

            CallReminderAlarmDialog {
                id: reminderDialog

                anchors.fill: parent
                opacity: 0.0
                onDialogHidden: page.dialogHidden(status)
            }

            Component.onCompleted: quitTimer.start()
        }
    }
}
