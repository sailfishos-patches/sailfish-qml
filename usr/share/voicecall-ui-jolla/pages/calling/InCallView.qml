import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Bluetooth 1.0
import Sailfish.Policy 1.0
import Sailfish.Telephony 1.0
import Nemo.Configuration 1.0
import org.nemomobile.notifications 1.0
import org.nemomobile.systemsettings 1.0
import org.nemomobile.voicecall 1.0 as VoiceCall
import org.nemomobile.messages.internal 1.0 as Messages
import com.jolla.voicecall 1.0
import "../../common/CallHistory.js" as CallHistory
import "../../common"

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
        }
    }

    anchors.fill: parent
    enabled: main.state !== 'incoming'
    interactive: !telephony.isEmergency && (main.state === "active" || main.state === "held" || main.state === "silenced")

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

    MouseArea {
        function dismiss() {
            root.completeAnimation()

            // If the menu is shown, close it
            if (menuLoader.item) {
                menuLoader.item.close()
            }
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
        visible: root.interactive
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
            property bool activate
            property bool menuActive: pullDownMenu.active
            onMenuActiveChanged: {
                if (!menuActive && activate) {
                    telephony.merge(telephony.primaryCall, telephony.heldCall)
                    activate = false
                }
            }
            // GSM 02.84 states that the maximum number of remote parties is 5
            visible: main.state === "active" && telephony.heldCall && (!telephony.conferenceCall || telephony.conferenceCall.childCalls.count < 5)
            //% "Merge calls"
            text: qsTrId("voicecall-me-merge_calls")
            onClicked: activate = true
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
                property bool activate
                property bool menuActive: pullDownMenu.active
                onMenuActiveChanged: {
                    if (!menuActive && activate) {
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
                        activate = false
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

                onClicked: activate = true
            }
        }
    }

    PushUpMenu {
        id: pushUpMenu
        visible: telephony.silencedCall && main.state !== "silenced"
        enabled: visible
        quickSelect: true
        MenuItem {
            property QtObject silencedCall: telephony.silencedCall
            onSilencedCallChanged: {
                if (silencedCall) {
                    var person = telephony.silencedCallerDetails.person
                    var label = CallHistory.callerNameShort(person, telephony.silencedCallerDetails.remoteUid)
                    //: Reject an incoming call which has been muted
                    //% "Reject %1"
                    text = qsTrId("voicecall-me-reject_muted_call").arg(label)
                }
            }
            onClicked: {
                telephony.hangupCall(silencedCall)
                main.hangupAnimation.complete()
            }
        }
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

            y: isPortrait ? Theme.itemSizeExtraLarge : _callerItem.height + Theme.paddingLarge
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
                            inCallKeypad = inCallKeypadComponent.createObject(root)
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
                icon: "icon-system-warning"
                //: System notification when MDM policy prevents microphone usage.
                //: %1 is an operating system name without the OS suffix
                //% "Microphone disabled by %1 Device Manager"
                previewBody: qsTrId("voicecall-la-microphone_disallowed_by_policy")
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
        height: parent.height
        width: controlContainer.width
        parent: isPortrait && inCallKeypad && inCallKeypad.open && !inCallKeypad.moving ? inCallKeypad : root.contentItem

        Row {
            property bool showDisconnectedButtons: main.state === "silenced"
                        || (main.state === 'null' || main.state === "disconnected")

            x: Theme.horizontalPageMargin
            y: endCallButton.y - height - Theme.itemSizeSmall

            width: parent.width - 2 * x

            enabled: showDisconnectedButtons && (!menuLoader.item || !menuLoader.item.active)
            opacity: enabled ? 1.0 : 0.0
            Behavior on opacity { FadeAnimation { id: disconnectTimer } }

            IconTextButton {
                //% "Send message"
                text: qsTrId("voicecall-bt-send_message")
                icon.source: "image://theme/icon-m-message"
                width: parent.width/2

                onClicked: {
                    menuLoader.sourceComponent = messageReplyMenuComponent
                    menuLoader.active = true
                }
            }

            IconTextButton {
                id: reminderButton

                //: Create a reminder to return a dismissed call
                //% "Remind me"
                text: qsTrId("voicecall-bt-create_reminder")
                icon.source: "image://theme/icon-m-alarm"
                description: callerItem.reminder.exists
                             ? Format.formatDate(callerItem.reminder.when, Formatter.TimeValue)
                             : ""
                width: parent.width/2

                onClicked: {
                    menuLoader.sourceComponent = reminderMenuComponent
                    menuLoader.active = true
                }
            }
        }

        Loader {
            id: menuLoader

            active: false
            sourceComponent: messageReplyMenuComponent
            onLoaded: {
                item.open(root)
            }
        }

        Button {
            id: endCallButton

            readonly property bool showEndCallButton: main.state !== "incoming"
                        && (!menuLoader.item || !menuLoader.item.active)
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
                horizontalCenter: parent.horizontalCenter
            }
            preferredWidth: Theme.buttonWidthMedium
            height: Theme.itemSizeLarge
            onClicked: {
                if (main.state === "silenced") {
                    telephony.hangupCall(telephony.silencedCall)
                    main.hangupAnimation.complete()
                } else if (main.state !== 'null' && main.state !== 'disconnected') {
                    telephony.hangupCall(telephony.primaryCall)
                }
            }
            enabled: showEndCallButton
            opacity: showEndCallButton ? 1.0 : 0.0
            Behavior on opacity { FadeAnimation { } }
        }
    }

    Component {
        id: bluetoothAudioComponent

        CurrentBluetoothAudioDevice { }
    }

    Component {
        id: messageReplyMenuComponent

        ContextMenu {
            id: messageReplyMenu

            property bool sending

            onClosed: {
                if (!messageReplyMenu.sending) {
                    // We're not sending an SMS, so we can just destroy the thing right now
                    menuLoader.active = false
                }
            }

            Label {
                font {
                    family: Theme.fontFamilyHeading
                    pixelSize: Theme.fontSizeLarge
                }
                anchors {
                    left: parent ? parent.left : undefined
                    leftMargin: Theme.horizontalPageMargin
                    right: parent ? parent.right : undefined
                    rightMargin: Theme.horizontalPageMargin
                    bottom: parent ? messageReplyMenu.top : undefined
                    bottomMargin: Theme.paddingLarge
                }

                color: palette.highlightColor
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                opacity: messageReplyMenu.active ? 1.0 : 0.0
                Behavior on opacity { FadeAnimator {} }

                // We can't have this item inside the ContextMenu because we don't want the background behind it,
                // ContextMenu sets its own parent, so we follow it.
                parent: messageReplyMenu.parent

                //: Header that appears on top of the message reply menu.
                //% "Select your message"
                text: qsTrId("voicecall-he-select_your_message")
            }

            Messages.SmsSender {
                id: smsSender

                function sendingDone() {
                    messageReplyMenu.sending = false

                    if (!messageReplyMenu.active) {
                        // Menu is already invisible, we can just destroy it now
                        menuLoader.active = false
                    }
                }

                onSendingSucceeded: sendingDone()
                onSendingFailed: sendingDone()
            }

            SimPickerMenuItem {
                id: simPickerMenuItem
                menu: messageReplyMenu
                actionType: Telephony.Message
            }

            Repeater {
                model: QuickMessagesModel {
                    id: quickMessagesModel
                }

                MenuItem {
                    id: menuItem

                    text: model.display.replace(/\n/g, ' ')
                    enabled: !messageReplyMenu.sending
                    onClicked: {
                        var number = (main.state === "silenced" ? telephony.silencedCallerDetails.remoteUid : telephony.lastCaller)

                        if (telephony.promptForSim(number)) {
                            simPickerMenuItem.active = true
                            simPickerMenuItem.simSelected.connect(function(sim, modemPath) {
                                menuItem.sendMessage(modemPath, number)
                            })
                        } else {
                            menuItem.sendMessage(telephony.simManager.activeModem, number)
                        }
                    }

                    function sendMessage(modemPath, number) {
                        messageReplyMenu.sending = true
                        main.hangupAnimation.complete()
                        smsSender.sendSMS(modemPath, number, model.display)

                        // If the call is silenced, hang up, otherwise it's already ended, so no need to do anything
                        if (main.state === "silenced") {
                            telephony.hangupCall(telephony.silencedCall)
                            main.hangupAnimation.complete()
                        }
                    }
                }
            }

            MenuItem {
                //: Appears in the message reply menu which has limited space,
                //: opens the Messages app and allow the user to write a custom message.
                //% "Enter your message"
                text: qsTrId("voicecall-me-custom_message")
                onClicked: {
                    __window.lower() // make sure Phone app __window doesn't become active in-between and call callingDialog().activate()
                    main.callingView.lower() // JB#47779: Explicitly minimize the call dialog to make sure Messages comes on top
                    var number = (main.state === "silenced" ? telephony.silencedCallerDetails.remoteUid : telephony.lastCaller)
                    messaging.startSMS(number)
                    main.hangupAnimation.complete()
                }
            }
        }
    }

    Component {
        id: reminderMenuComponent

        ReminderContextMenu {
            id: reminderMenu

            number: main.state === "silenced"
                    ? telephony.silencedCallerDetails.remoteUid
                    : telephony.lastCaller
            person: main.state === "silenced"
                    ? telephony.silencedCallerDetails.person
                    : people.personByPhoneNumber(telephony.lastCaller)

            onClosed: menuLoader.active = false

            Label {
                parent: reminderMenu.parent
                font {
                    family: Theme.fontFamilyHeading
                    pixelSize: Theme.fontSizeLarge
                }

                anchors {
                    left: parent ? parent.left : undefined
                    leftMargin: Theme.horizontalPageMargin
                    right: parent ? parent.right : undefined
                    rightMargin: Theme.horizontalPageMargin
                    bottom: parent ? reminderMenu.top : undefined
                    bottomMargin: Theme.paddingLarge
                }

                color: palette.highlightColor
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap

                //: Header that appears on top of the call back reminder menu.
                //% "Remind me"
                text: qsTrId("voicecall-he-remind_me")
            }
        }
    }

    AboutSettings {
        id: aboutSettings
    }
}
