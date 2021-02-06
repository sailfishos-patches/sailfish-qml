/*
 * Copyright (c) 2012 - 2020 Jolla Ltd.
 * Copyright (c) 2019 - 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Bluetooth 1.0
import Sailfish.Policy 1.0
import Sailfish.Telephony 1.0
import Nemo.Configuration 1.0
import org.nemomobile.notifications 1.0
import org.nemomobile.systemsettings 1.0
import org.nemomobile.voicecall 1.0 as VoiceCall
import "../common/CallHistory.js" as CallHistory
import "../common"

SilicaFlickable {
    id: root

    // The checked properties of the switches aren't bound to directly because they overwrite
    // the value (which removes the binding) when clicked on.
    property bool isSpeaker: telephony.audioMode == 'ihf'
    property bool isMicrophoneMuted: telephony.isMicrophoneMuted
    property string callState: main.state
    property Item inCallKeypad
    property CurrentBluetoothAudioDevice bluetoothAudio
    property bool bluetoothAudioAvailable: bluetoothAudio != null && bluetoothAudio.available
    property bool keypadOpen: inCallKeypad && inCallKeypad.open
    property QtObject caller: telephony.primaryCall ? telephony.primaryCallerDetails : telephony.silencedCallerDetails

    signal completeAnimation()
    signal setAudioRecording(bool recording)

    onIsSpeakerChanged: speakerSwitch.checked = isSpeaker
    onIsMicrophoneMutedChanged: microphoneSwitch.checked = isMicrophoneMuted

    onCallStateChanged: {
        if (bluetoothAudio == null) {
            // Create this object on demand to reduce system load from responding to detection of
            // nearby Bluetooth devices when there are no on-going calls.
            bluetoothAudio = bluetoothAudioComponent.createObject(root)
        } else if (bluetoothAudio.available) {
            if (callState == 'dialing' || callState == 'incoming') {
                bluetoothAudio.reset()
            }
        }

        if (callState == 'null' || callState == 'disconnected') {
            if (inCallKeypad) {
                inCallKeypad.fade()
            }
            if (bluetoothAudio != null) {
                bluetoothAudio.destroy()
                bluetoothAudio = null
            }
            dtmfLabelTimer.stop()

            // Dismiss the notice about premium or toll-free number
            Notices._dismissCurrent()
        }

        // Show a notice when calling a premium-rate or toll-free phone number
        if (callState === "alerting") {
            // Position the notice above the end call button
            var endCallPos = root.mapFromItem(endCallButton, 0, 0)
            var noticeVerticalCenterOffset = -(root.height - endCallPos.y)
            var noticeText = ""

            if (phoneNumberParser.numberType === PhoneNumber.NumberTypePremium) {
                //% "Calling this number may cost you extra."
                noticeText = qsTrId("voicecall-no-incall_premium")
            } else if (phoneNumberParser.numberType === PhoneNumber.NumberTypeTollFree) {
                //% "This number is toll-free."
                noticeText = qsTrId("voicecall-no-incall_tollfree")
            }

            if (noticeText !== "") {
                Notices.show(noticeText, Notice.Long, Notice.Bottom, 0, noticeVerticalCenterOffset)
            }
        }
    }

    anchors.fill: parent
    enabled: main.state !== 'incoming' && main.state !== "silenced"
    interactive: !telephony.isEmergency
                 && (main.state === "active" || main.state === "held")

    opacity: enabled ? 1.0 : 0.0
    contentHeight: height

    function reset() {
        telephony.audioMode = "earpiece"
        // passing true to hide() makes hiding immediate
        if (inCallKeypad) {
            inCallKeypad.hide(true)
        }
        telephony.isMicrophoneMuted = false
    }

    function qsTrIdStrings()
    {
        //% "Cancel"
        QT_TRID_NOOP("voicecall-bt-cancel")
        //% "End call"
        QT_TRID_NOOP("voicecall-bt-end_call")

        //% "Mute"
        QT_TRID_NOOP("voicecall-la-mute")
        //% "Speaker"
        QT_TRID_NOOP("voicecall-la-speaker")

        //% "On hold"
        QT_TRID_NOOP("voicecall-la-held_state")
        //% "Dialing"
        QT_TRID_NOOP("voicecall-la-dialing_state")
        //% "Alerting"
        QT_TRID_NOOP("voicecall-la-alerting_state")
        //% "Incoming"
        QT_TRID_NOOP("voicecall-la-incoming_state")
        //% "Waiting"
        QT_TRID_NOOP("voicecall-la-waiting_state")
        //% "Silenced"
        QT_TRID_NOOP("voicecall-la-silenced_state")
    }

    Behavior on opacity { FadeAnimator { duration: 400 } }

    PhoneNumber {
        id: phoneNumberParser
        defaultRegionCode: telephony.country
        rawPhoneNumber: caller ? caller.remoteUid : ""
    }

    MouseArea {
        function dismiss() {
            root.completeAnimation()

        }

        onClicked: dismiss()
        anchors.fill: parent
        enabled: main.state === "null" || main.state === "disconnected" || main.state === "silenced"

    }

    Connections {
        target: telephony
        onActiveChanged: {
            if (telephony.active) {
                root.reset()
            }
        }
    }

    PullDownMenu {
        id: pullDownMenu
        enabled: !callItem.enabled && (telephony.effectiveCallCount > 1 || main.state !== "silenced")
        visible: root.interactive && enabled
        quickSelect: main.state === "silenced"
        property bool animWasPaused
        onActiveChanged: {
            if (active && main.hangupAnimation.running) {
                animWasPaused = main.hangupAnimation.paused
                main.hangupAnimation.pause()
            } else if (!active && main.hangupAnimation.paused) {
                main.hangupAnimation.paused = animWasPaused
            }
        }

        MenuItem {
            visible: telephony.conferenceCall
            //% "Manage Conference"
            text: qsTrId("voicecall-me-manage_conference")
            onClicked: {
                callDialogApplicationWindow.pageStack.animatorPush(Qt.resolvedUrl("ConferenceManager.qml"))
            }
        }
        MenuItem {
            // GSM 02.84 states that the maximum number of remote parties is 5
            visible: main.state === "active" && telephony.heldCall && (!telephony.conferenceCall || telephony.conferenceCall.childCalls.count < 5)
            //% "Merge calls"
            text: qsTrId("voicecall-me-merge_calls")
            onDelayedClick: {
                telephony.merge(telephony.primaryCall, telephony.heldCall)
                activate = false
            }
        }
        MenuItem {
            visible: telephony.effectiveCallCount === 1 && main.state !== "silenced"
            //% "Add call"
            text: qsTrId("voicecall-me-add_call")
            onClicked: main.addCallMode = true
        }

        Repeater {
            model: telephony.voiceCalls
            delegate: MenuItem {
                visible: (callCount == 1 || (statusText === "held" && !telephony.silencedCall) || isSilenced) && parentCall == null && telephony.voiceCalls.count >= 1
                onVisibleChanged: updateAction()
                property int callCount: telephony.effectiveCallCount
                onCallCountChanged: updateAction()
                property int callStatus: status
                onCallStatusChanged: updateAction()
                property string mainState: main.state
                onMainStateChanged: updateAction()
                property bool isSilenced: telephony.silencedCall ? telephony.silencedCall.handlerId == instance.handlerId : false

                onDelayedClick: {
                    if (isSilenced) {
                        if (callCount > 2) {
                            // We have one call on hold and another active. End the active call and answer incoming.
                            telephony.releaseAndAnswer()
                        } else {
                            instance.answer()
                        }
                    } else {
                        instance.hold(statusText !== "held")
                    }
                }

                function updateAction() {
                    var person
                    var label

                    if (!instance) {
                        console.warn("instance was empty")
                        return
                    }

                    if (isSilenced) {
                        person = telephony.callerDetails[instance.handlerId].person
                        label = CallHistory.callerNameShort(person, telephony.callerDetails[instance.handlerId].remoteUid)

                        //: Answer an incoming call which has been muted
                        //% "Answer %1"
                        text = qsTrId("voicecall-me-answer_muted_call").arg(label)
                    } else if (callCount === 1) {
                        text = statusText === "held"
                                ? //% "Resume call"
                                  qsTrId("voicecall-me-resume_call")
                                : //% "Hold call"
                                  qsTrId("voicecall-me-hold_call")
                    } else {
                        if (statusText === "held") {
                            person = telephony.callerDetails[instance.handlerId].person
                            label = CallHistory.callerNameShort(person, telephony.callerDetails[instance.handlerId].remoteUid)
                            text = main.state === 'active'
                                    ? //% "Switch to %1"
                                      qsTrId("voicecall-me-switch_to_call").arg(label)
                                    : //% "Resume call with %1"
                                      qsTrId("voicecall-me-resume_call_with").arg(label)
                        } else {
                            //% "Hold call"
                            text = qsTrId("voicecall-me-hold_call")
                        }
                    }
                }
            }
        }
    }

    CallerItem {
        id: callItem
        person: telephony.silencedCallerDetails ? telephony.silencedCallerDetails.person : undefined
        remoteUid: telephony.silencedCallerDetails ? telephony.silencedCallerDetails.remoteUid : undefined
        enabled: telephony.silencedCall && telephony.primaryCall
        opacity: enabled ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator {}}

        onClicked: {
            // state update will reset to incoming call, the normal priority status
            telephony.updateState()
        }
        //: Shown on a tappable green banner representing the incoming call,
        //: next to the caller name or phone number
        //% "incoming"
        secondaryText: qsTrId("voicecall-bt-incoming")
    }

    Item {
        id: controlContainer
        height: parent.height
        width: parent.width

        states: State {
            name: "splitview"
            when: keypadOpen
            PropertyChanges {
                target: controlContainer
                width: root.width / (isLandscape ? 2 : 1)
            }
        }
        transitions: Transition {
            NumberAnimation {
                properties: "width"
                duration: inCallKeypad && inCallKeypad.animationDuration
                easing.type: Easing.InOutQuad
            }
        }

        HighlightImage {
            opacity: telephony.primaryCall && telephony.primaryCall.isForwarded && !dtmfLabelTimer.running && (main.state === "active" || main.state === "calling" || main.state === "incoming") ? 1.0 : 0.0
            Behavior on opacity { FadeAnimation {} }
            x: (parent.width - stateLabel.contentWidth)/2 - width - Theme.paddingMedium
            anchors.verticalCenter: stateLabel.verticalCenter
            source: "image://theme/icon-m-redirect"
            color: palette.highlightColor
        }

        Label {
            id: stateLabel

            property string stateString: stateToString(main.state)

            // highlight call duration hours, minutes and seconds with non-zero numbers
            readonly property color _durationZeroNumbersColor: telephony.isEmergency
                    ? Theme.rgba("red", Silica.Theme.opacityHigh)
                    : palette.secondaryHighlightColor

            function stateToString(state)
            {
                if (state === "active" || state === "calling") {
                    return CallHistory.highlightedDurationText(telephony.callDuration, _durationZeroNumbersColor)
                } else if (state === "incoming") {
                    return ""
                } else if (state === "held") {
                    return qsTrId("voicecall-la-held_state")
                } else if (state === "dialing") {
                    return qsTrId("voicecall-la-dialing_state")
                } else if (state === "alerting") {
                    return qsTrId("voicecall-la-alerting_state")
                } else if (state === "waiting") {
                    return qsTrId("voicecall-la-waiting_state")
                } else if (state === "silenced") {
                    return qsTrId("voicecall-la-silenced_state")
                } else if (state === "null" || state === "disconnected") {
                    return telephony.callDuration === 0
                            ? telephony.error
                            : "%1<br/>%2".arg(CallHistory.highlightedDurationText(telephony.callDuration, _durationZeroNumbersColor)).arg(telephony.error)

                } else {
                    console.log("InCallView error! Unknown VoiceCallManager active call state: " + state)
                    return ""
                }
            }

            readonly property bool aspectRatioNarrow: root.height/root.width > 2.1

            y: isPortrait ? Math.round(parent.height / (aspectRatioNarrow ? 7 : 8))
                          : _callerItem.height + Theme.paddingLarge
            opacity: dtmfLabelTimer.running ? 0.0 : 1.0
            text: stateString
            color: telephony.isEmergency ? "red" : palette.highlightColor
            x: Theme.horizontalPageMargin
            width: parent.width - 2*Theme.horizontalPageMargin
            wrapMode: Text.Wrap
            textFormat: Text.StyledText
            horizontalAlignment: Text.AlignHCenter
            font { pixelSize: Theme.fontSizeHuge; family: Theme.fontFamilyHeading }
            Behavior on opacity { FadeAnimation {} }
        }

        OpacityRampEffect {
            sourceItem: dtmfToneLabelWrapper
            direction: OpacityRamp.RightToLeft
            offset: 0.75
            slope: 4
        }

        MouseArea { // needed for making opacity ramp invariant of label position
            id: dtmfToneLabelWrapper

            enabled: callState === "active" || callState === "calling"
            onClicked: {
                if (dtmfLabelTimer.running) {
                    dtmfLabelTimer.stop()
                } else if (telephony.dtmfToneHistory.length > 0) {
                    dtmfLabelTimer.restart()
                }
            }

            height: dtmfToneLabel.height
            anchors {
                left: parent.left
                right: parent.right
                margins: Theme.horizontalPageMargin
                verticalCenter: stateLabel.verticalCenter
            }

            Label {
                id: dtmfToneLabel
                width: parent.width
                color: telephony.isEmergency ? "red" : palette.highlightColor
                text: telephony.dtmfToneHistory
                horizontalAlignment: implicitWidth > parent.width ? Text.AlignRight : Text.AlignHCenter
                opacity: dtmfLabelTimer.running ? 1.0 : 0.0
                font { pixelSize: Theme.fontSizeHuge; family: Theme.fontFamilyHeading }
                onTextChanged: dtmfLabelTimer.restart()
                Timer { id: dtmfLabelTimer; interval: 4000 }
                Behavior on opacity { FadeAnimation {} }
            }
        }

        Label {
            id: simNameLabel

            property string callSimName: telephony.simNameForCall(telephony.primaryCall)

            anchors {
                top: stateLabel.bottom
                topMargin: visible ? Theme.paddingSmall : 0
            }
            height: visible ? implicitHeight : 0
            width: parent.width - 2*x
            x: Theme.paddingLarge
            truncationMode: TruncationMode.Fade
            color: stateLabel.color
            horizontalAlignment: implicitWidth > width ? Text.AlignLeft : Text.AlignHCenter
            opacity: stateLabel.opacity
            font.pixelSize: Theme.fontSizeSmall
            visible: callSimName.length > 0.0
            text: (main.state !== "disconnected" && main.state !== "null") ? callSimName : ""
        }

        Row {
            id: buttonRow
            property bool callButtonsEnabled: main.state !== 'null' && main.state !== "silenced" && main.state !== "disconnected" && main.state !== "incoming"
            spacing: Theme.paddingSmall
            enabled: callButtonsEnabled
            opacity: callButtonsEnabled ? 1.0 : 0.0
            Behavior on opacity { FadeAnimation { } }
            anchors {
                topMargin: -Theme.paddingMedium
                top: simNameLabel.bottom
                horizontalCenter: parent.horizontalCenter
            }

            Switch {
                id: bluetoothAudioSwitch
                visible: bluetoothAudioAvailable && bluetoothAudio.supportsCallAudio
                icon.source: bluetoothAudioAvailable && bluetoothAudio.jollaIcon != "" ? "image://theme/" + bluetoothAudio.jollaIcon : ""
                automaticCheck: false
                checked: !speakerSwitch.checked && bluetoothAudioAvailable && bluetoothAudio.callAudioEnabled

                onClicked: {
                    if (!speakerSwitch.checked && bluetoothAudio.callAudioEnabled) {
                        bluetoothAudio.disableAudioStream()
                    } else {
                        speakerSwitch.checked = false
                        bluetoothAudio.enableAudioStream()
                    }
                }

                AudioSwitchConnector {
                    x: bluetoothAudioSwitch.width / 2
                    y: Theme.itemSizeMedium/2 - height/2   // Theme.itemSizeMedium = glass item default height
                    width: parent.width
                }

                Component {
                    id: bluetoothAudioComponent

                    CurrentBluetoothAudioDevice { }
                }
            }

            Switch {
                id: speakerSwitch
                icon.source: "image://theme/icon-m-speaker"
                onCheckedChanged: {
                    if (checked) {
                        if (bluetoothAudioAvailable && bluetoothAudio.supportsCallAudio) {
                            bluetoothAudio.disableAudioStream()
                        }
                        telephony.audioMode = 'ihf'
                    } else {
                        telephony.audioMode = 'earpiece'
                    }
                }
            }

            Switch {
                id: dialerSwitch
                icon.source: "image://theme/icon-m-dialpad"
                onCheckedChanged: {
                    if (checked && !inCallKeypad) {
                        var inCallKeypadComponent = Qt.createComponent("InCallKeypad.qml")

                        if (inCallKeypadComponent.status === Component.Ready) {
                            inCallKeypad = inCallKeypadComponent.createObject(keypadParent)
                            inCallKeypad.button = endCallButton
                        } else {
                            console.log(inCallKeypadComponent.errorString())
                        }
                    }
                    inCallKeypad.open = checked
                }
            }

            Switch {
                id: microphoneSwitch
                iconSource: "image://theme/icon-m-mic-mute"
                enabled: !telephony.isEmergency
                onCheckedChanged: {
                    telephony.isMicrophoneMuted = checked
                }
            }

            Switch {
                iconSource: "image://theme/icon-m-call-recording-" + (checked ? "on" : "off")
                // Only show if call recording is available on this device
                visible: callRecordingConfig.value && VoiceCall.VoiceCallAudioRecorder.available
                automaticCheck: false
                checked: VoiceCall.VoiceCallAudioRecorder.recording
                opacity: AccessPolicy.microphoneEnabled ? 1.0 : Theme.opacityHigh
                onClicked: {
                    var recording = !checked
                    if (recording && !AccessPolicy.microphoneEnabled) {
                        microphoneWarningNotification.publish()
                    }

                    root.setAudioRecording(recording)
                }

                ConfigurationValue {
                    id: callRecordingConfig
                    key: "/jolla/voicecall/call_recording"
                    defaultValue: false
                }
            }

            Notification {
                id: microphoneWarningNotification

                isTransient: true
                urgency: Notification.Critical
                appIcon: "icon-system-warning"
                //: System notification when MDM policy prevents microphone usage.
                //: %1 is an operating system name without the OS suffix
                //% "Microphone disabled by %1 Device Manager"
                body: qsTrId("voicecall-la-microphone_disallowed_by_policy")
                    .arg(aboutSettings.baseOperatingSystemName)
            }
        }

        Label {
            //: Advises user to not end an emergency call until advised to by the operator.
            //% "Do not end call until you are advised to do so."
            text: qsTrId("voicecall-la-emergency_call_advice")
            color: Theme.rgba("red", Theme.opacityHigh)
            opacity: telephony.isEmergency ? 1.0 : 0.0
            Behavior on opacity { FadeAnimation {} }
            x: Theme.horizontalPageMargin
            width: parent.width - 2*Theme.horizontalPageMargin
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            font { pixelSize: Theme.fontSizeExtraLarge; family: Theme.fontFamilyHeading }
            anchors { top: buttonRow.bottom; topMargin: Theme.paddingLarge }
        }
    }

    Item {
        id: keypadParent

        width: root.width
        height: root.height
    }

    FooterButton {
        id: endCallButton

        readonly property bool showEndCallButton: main.state !== "incoming"
                                                  && (main.state !== "null" && main.state !== "disconnected")
        readonly property string labelText: {
            if (main.state === "incoming") {
                return ""
            } else if (main.state === 'dialing' || main.state === 'alerting') {
                return qsTrId("voicecall-bt-cancel")
            } else if (main.state === 'silenced') {
                //% "Reject call"
                return qsTrId("voicecall-bt-reject_call")
            } else if (main.state !== 'null' && main.state !== 'disconnected') {
                return qsTrId("voicecall-bt-end_call")
            } else {
                return ""
            }
        }
        onLabelTextChanged: {
            // Keep the old text if the button is being hidden to avoid flicker.
            if (labelText !== "") {
                text = labelText
            }
        }

        anchors {
            bottom: parent.bottom
            bottomMargin: endCallButton.bottomMargin
        }

        onClicked: {
            if (main.state !== 'null' && main.state !== 'disconnected') {
                telephony.hangupCall(telephony.primaryCall)
            }
        }
        enabled: showEndCallButton
        opacity: showEndCallButton ? 1.0 : 0.0
        Behavior on opacity { FadeAnimation { } }
    }

    AboutSettings {
        id: aboutSettings
    }
}
