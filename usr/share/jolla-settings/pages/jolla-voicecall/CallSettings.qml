import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.voicecall.settings.translations 1.0
import QOfono 0.2

Item {
    id: callSettings
    property alias modemPath: ofonoCallSettings.modemPath
    property bool responsePending: callerId.responsePending || callWaiting.responsePending
    property real _optionOpacity: ofonoCallSettings.ready ? 1.0 : 0.0
    Behavior on _optionOpacity { FadeAnimation {} }

    height: settingsContent.height

    Column {
        id: settingsContent
        width: parent.width
        Item {
            id: callerId
            property bool responsePending
            width: parent.width
            height: callerIdCombo.height + (callerIdErrorLabel.visible ? callerIdErrorLabel.height : 0)
            opacity: callSettings._optionOpacity

            ComboBox {
                id: callerIdCombo
                anchors.left: parent.left
                anchors.right: callerId.responsePending ? callerIdProgress.left : parent.right
                anchors.rightMargin: callerId.responsePending ? Theme.paddingLarge : 0
                //% "Show my caller ID"
                label: qsTrId("settings_phone-la-show_caller_id")
                enabled: !callerId.responsePending && ofonoCallSettings.ready && ofonoCallSettings.callingLineRestriction != "disabled"
                currentIndex: -1

                onCurrentIndexChanged: {
                    var newValue = ofonoCallSettings.hideCallerId
                    switch (currentIndex) {
                    case 0:
                        newValue = "default"
                        break
                    case 1:
                        newValue = "disabled"
                        break
                    case 2:
                        newValue = "enabled"
                        break
                    }
                    if (newValue !== ofonoCallSettings.hideCallerId) {
                        callerId.responsePending = true
                        ofonoCallSettings.hideCallerId = newValue
                    }
                }

                menu: ContextMenu {
                    MenuItem {
                        //% "Set by network"
                        text: qsTrId("settings_phone-me-callerid_network_default")
                    }
                    MenuItem {
                        //% "Yes"
                        text: qsTrId("settings_phone-me-callerid_yes")
                    }
                    MenuItem {
                        //% "No"
                        text: qsTrId("settings_phone-me-callerid_no")
                    }
                }
            }
            BusyIndicator {
                id: callerIdProgress
                height: callerIdCombo.height
                width: height
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin
                running: callerId.responsePending
                visible: running
            }
            Label {
                id: callerIdErrorLabel
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin*2
                anchors.top: callerIdCombo.bottom
                visible: false
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.Wrap
                //% "Changing the caller ID status failed"
                text: qsTrId("settings_phone-la-cannot_update_callerid")
            }
        }

        Item {
            id: callWaiting
            property bool responsePending
            width: parent.width
            height: callWaitingSwitch.height + (callWaitingErrorLabel.visible ? callWaitingErrorLabel.height : 0)
            opacity: callSettings._optionOpacity

            TextSwitch {
                id: callWaitingSwitch
                width: parent.width
                busy: callWaiting.responsePending
                //% "Call waiting"
                text: qsTrId("settings_phone-la-call_waiting")
                enabled: !callWaiting.responsePending && ofonoCallSettings.ready
                onCheckedChanged: {
                    var newValue = checked ? "enabled" : "disabled"
                    if (newValue !== ofonoCallSettings.voiceCallWaiting) {
                        callWaiting.responsePending = true
                        ofonoCallSettings.voiceCallWaiting = newValue
                    }
                }
            }
            Label {
                id: callWaitingErrorLabel
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin*2
                anchors.top: callWaitingSwitch.bottom
                visible: false
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.Wrap
                //% "Changing the status of call waiting failed"
                text: qsTrId("settings_phone-la-cannot_update_call_waiting")
            }
        }
    }
    Column {
        id: networkProgress
        width: parent.width
        height: settingsContent.height
        spacing: Theme.paddingMedium
        opacity: 1.0-callSettings._optionOpacity
        visible: opacity > 0.0 && ofonoModem.online
        Label {
            id: busyLabel
            //% "Retrieving settings"
            text: qsTrId("settings_voicecall-la-retrieving_settings")
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.highlightColor
        }
        BusyIndicator {
            running: parent.visible
            height: Theme.itemSizeLarge
            width: height
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    OfonoCallSettings {
        id: ofonoCallSettings
        function updateCallerId() {
            if (hideCallerId == "default") {
                callerIdCombo.currentIndex = 0
            } else if (hideCallerId == "disabled") {
                callerIdCombo.currentIndex = 1
            } else if (hideCallerId == "enabled") {
                callerIdCombo.currentIndex = 2
            }
        }
        onHideCallerIdChanged: {
            updateCallerId()
        }
        onVoiceCallWaitingChanged: {
            callWaitingSwitch.checked = voiceCallWaiting == "enabled"
        }
        onHideCallerIdComplete: {
            callerId.responsePending = false
            callerIdErrorLabel.visible = !success
            if (!success) {
                updateCallerId()
            }
        }
        onVoiceCallWaitingComplete: {
            callWaiting.responsePending = false
            callWaitingErrorLabel.visible = !success
            if (!success) {
                callWaitingSwitch.checked = voiceCallWaiting == "enabled"
            }
        }
    }
}
