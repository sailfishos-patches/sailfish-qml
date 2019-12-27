import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as SilicaPrivate
import Sailfish.Lipstick 1.0
import Sailfish.Telephony 1.0
import com.jolla.voicecall 1.0
import "../../common"
import "../../common/CallHistory.js" as CallHistory

SystemDialog {
    id: root

    property string remoteUid
    property string callerName
    property alias reminder: reminder

    property QtObject _simPicker

    readonly property int _windowMargin: Theme.paddingMedium

    property real _buttonWidth: {
        var visibleCount = 0
        var buttons = [sendMsgButton, removeReminderButton, callButton]
        for (var i = 0; i < buttons.length; ++i) {
            if (buttons[i].visible) {
                visibleCount++
            }
        }
        return content.width / visibleCount
    }

    function init(callInstance, callerDetails) {
        remoteUid = callInstance ? callInstance.lineId : ""
        callerName = callerDetails && callerDetails.person ? callerDetails.person.displayLabel : ""
    }

    function sendMessage() {
        messaging.startSMS(remoteUid)
    }

    function redial(modemPath) {
        telephony.dial(remoteUid, modemPath)
    }

    function _showSimPicker() {
        if (!_simPicker) {
            _simPicker = simPickerComponent.createObject(content)
        }
        _simPicker.visible = true
    }

    category: SystemDialogWindow.Call

    layoutItem.contentItem.x: {
        var w = (orientation === Qt.PortraitOrientation || orientation === Qt.InvertedPortraitOrientation ? width : height)
        return (w / 2) - (layoutItem.contentItem.width / 2)
    }
    layoutItem.contentItem.y: layoutItem.height - layoutItem.contentItem.height - _windowMargin
    layoutItem.contentItem.width: Screen.width - _windowMargin*2    // content width = Screen.width in all orientations
    layoutItem.contentItem.height: content.y + content.height

    backgroundRect: {
        switch (orientation) {
        case Qt.LandscapeOrientation:
            return Qt.rect(_windowMargin,
                           (Screen.height/2 - Screen.width/2) + _windowMargin,
                           layoutItem.contentItem.height,
                           Screen.width - _windowMargin*2)
        case Qt.InvertedPortraitOrientation:
            return Qt.rect(_windowMargin,
                           _windowMargin,
                           Screen.width - _windowMargin*2,
                           layoutItem.contentItem.height)
        case Qt.InvertedLandscapeOrientation:
            return Qt.rect((width - layoutItem.contentItem.height) - _windowMargin,
                           (Screen.height/2 - Screen.width/2) + _windowMargin,
                           layoutItem.contentItem.height,
                           Screen.width - _windowMargin*2)
        case Qt.PortraitOrientation:
        default:
            return Qt.rect(_windowMargin,
                           (Screen.height - layoutItem.contentItem.height) - _windowMargin,
                           Screen.width - _windowMargin*2,
                           layoutItem.contentItem.height)
        }
    }

    onVisibleChanged: {
        if (!visible) {
            if (!reminder.exists) {
                removeReminderButton.visible = false
            }
            if (_simPicker) {
                _simPicker.destroy()
                _simPicker = null
            }
        }
    }

    // close dialog if clicked above button row
    MouseArea {
        width: parent.width
        height: content.y + buttonRow.y
        onClicked: root.dismiss()
    }

    Timer {
        interval: 10 * 1000
        running: root.visible
                 && !closeButton.pressed
                 && !sendMsgButton.pressed
                 && !removeReminderButton.pressed
                 && !callButton.pressed
        onTriggered: dismiss()
    }

    // Hide if loses top window position, e.g. due to blanking
    Connections {
        target: Qt.application
        onActiveChanged: if (!Qt.application.active) close()
    }

    IconButton {
        id: closeButton
        anchors {
            top: parent.top
            topMargin: Theme.paddingMedium
            right: parent.right
            rightMargin: Theme.paddingMedium
        }
        icon.source: "image://theme/icon-m-reset"
        onClicked: root.dismiss()
    }

    Label {
        id: callerNameLabel

        anchors {
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
            verticalCenter: closeButton.verticalCenter
        }

        width: parent.width - 2*Theme.horizontalPageMargin
        text: root.callerName || root.remoteUid
        color: Theme.highlightColor
    }

    Column {
        id: content

        anchors.top: callerNameLabel.bottom
        width: parent.width

        SystemDialogHeader {
            id: header

            title: telephony.error.length > 0
                   ? telephony.error
                   : "%1<br>%2".arg(CallHistory.durationText(telephony.callDuration))
                               .arg(qsTrId("voicecall-la-remote-hangup")) // tr in VoiceCallManager
            titleFont.pixelSize: Theme.fontSizeExtraLarge
            titleTextFormat: Text.StyledText
        }

        Row {
            id: buttonRow

            width: parent.width
            height: Math.max(sendMsgButton.implicitHeight,
                             removeReminderButton.implicitHeight,
                             callButton.implicitHeight)

            CallEndedDialogButton {
                id: sendMsgButton

                width: root._buttonWidth
                height: parent.height
                //% "Send message"
                text: qsTrId("voicecall-bt-send_message")
                visible: !telephony.callEndedLocally
                iconSource: "image://theme/icon-m-message"
                roundedCorners: SilicaPrivate.BubbleBackground.BottomLeft

                onPressed: {
                    if (_simPicker) {
                        _simPicker.visible = false
                    }
                }

                onClicked: {
                    root.sendMessage()
                    root.dismiss()
                }
            }

            CallEndedDialogButton {
                id: removeReminderButton

                width: root._buttonWidth
                height: parent.height

                text: enabled
                        //% "Remove reminder"
                      ? qsTrId("voicecall-bt-remove_reminder")
                        //% "Reminder removed"
                      : qsTrId("voicecall-bt-reminder_removed")
                iconSource: "image://theme/icon-m-alarm"
                roundedCorners: SilicaPrivate.BubbleBackground.NoCorners

                // Keep the button visible if the user has manually removed the reminder, to
                // avoid suddenly changing the layout when this happens.
                visible: false
                enabled: reminder.exists

                description: reminder.exists
                             ? Format.formatDate(reminder.when, Formatter.TimeValue)
                             : (visible ? " " : "") // use non-empty text when reminder removed to avoid resizing window while visible

                onClicked: {
                    reminder.remove()
                }
            }

            CallEndedDialogButton {
                id: callButton

                width: root._buttonWidth
                height: parent.height
                //% "Call again"
                text: qsTrId("voicecall-bt-call_again")
                iconSource: "image://theme/icon-m-call"
                visible: !telephony.callEndedLocally
                enabled: !_simPicker || !_simPicker.visible
                roundedCorners: SilicaPrivate.BubbleBackground.BottomRight

                onClicked: {
                    if (telephony.promptForSim(root.remoteUid)) {
                        root._showSimPicker()
                    } else {
                        root.redial("")
                        root.dismiss()
                    }
                }
            }
        }
    }

    Reminder {
        id: reminder
        phoneNumber: root.remoteUid
        _reminders: Reminders

        onExistsChanged: {
            if (exists && !removeReminderButton.visible) {
                removeReminderButton.visible = true
            }
        }
    }

    Component {
        id: simPickerComponent

        SimPicker {
            width: parent.width
            showBackground: true
            actionType: Telephony.Call

            onSimSelected: {
                root.redial(modemPath)
                root.dismiss()
            }
        }
    }
}
