import QtQuick 2.6
import Sailfish.Silica 1.0
import QOfono 0.2
import org.nemomobile.lipstick 0.1
import org.nemomobile.ofono 1.0
import org.nemomobile.systemsettings 1.0

FocusScope {
    id: root

    // read-only
    property alias enteredPin: pinInput.text
    property bool emergency
    property bool enteringNewPin

    property bool showCancelButton: true
    property bool showOkButton: true
    property bool busy

    property int minimumLength: 4
    property int maximumLength

    // modem for emergency calls
    property string modemPath: modemManager.defaultVoiceModem || manager.defaultModem

    property string titleText
    property color titleColor: Theme.secondaryHighlightColor
    property string subTitleText
    property string warningText
    property string transientWarningText
    property color warningTextColor: _inputOrCancelEnabled ? Theme.primaryColor : Theme.secondaryHighlightColor
    property bool highlightTitle: !_inputOrCancelEnabled && !emergency
    property color pinDisplayColor: Theme.highlightColor
    property color keypadTextColor: Theme.primaryColor
    property color keypadSecondaryTextColor: palette.secondaryColor
    property bool dimmerBackspace
    property color emergencyTextColor: "#ff4d4d"

    property alias passwordMaskDelay: pinInput.passwordMaskDelay

    property alias _passwordCharacter: pinInput.passwordCharacter
    property alias _displayedPin: pinInput.displayText
    property string _oldPin
    property string _newPin
    readonly property bool _validInput: pinInput.length >= minimumLength
                                        && (maximumLength <= 0 || pinInput.length <= maximumLength)
                                        && (!validator || validator.test(pinInput.text))

    property real headingVerticalOffset

    property string _pinConfirmTitleText
    property string _badPinWarning
    property string _overridingTitleText
    property string _emergencyWarningText

    // TODO: suggestions now only for digit mode. also the properties could be refactored,
    // suggestionsEnabled does not enable suggestions. JB#57962
    property bool suggestionsEnabled
    property bool suggestionsEnforced
    readonly property bool _showSuggestionButton: suggestionsEnabled
                && (suggestionsEnforced || pinInput.length === 0 || suggestionVisible)
    readonly property bool suggestionVisible: pinInput.length > 0
                && pinInput.selectionStart !== pinInput.selectionEnd

    // Allow requesting acknowledgement without needing to input pin
    property bool requirePin: true

    property bool showEmergencyButton: true

    //: Warns that the entered PIN was too long.
    //% "PIN cannot be more than %n characters."
    property string pinLengthWarning: qsTrId("settings_pin-la-pin_max_length_warning", maximumLength)
    property string pinShortLengthWarning
    //: Enter a new PIN code
    //% "Enter new PIN"
    property string enterNewPinText: qsTrId("settings_pin-he-enter_new_pin")
    //: Re-enter the PIN code that was just entered
    //% "Re-enter new PIN"
    property string confirmNewPinText: qsTrId("settings_pin-he-reenter_new_pin")
    //: Shown when a new PIN is entered twice for confirmation but the two entered PINs are not the same.
    //% "Re-entered PIN did not match."
    property string pinMismatchText: qsTrId("settings_pin-he-reentered_pin_mismatch")
    //: Shown when the new PIN is not allowed because it is the same as the current PIN.
    //% "The new PIN cannot be the same as the current PIN."
    property string pinUnchangedText: qsTrId("settings_pin-he-new_pin_same_as_old")

    readonly property string _pinValidationWarningText: {
        if (enteredPin === "") {
            return ""
        } else if (enteringNewPin && _oldPin === enteredPin) {
            return pinUnchangedText
        } else if (_pinMismatch) {
            return pinMismatchText
        } else if (pinInput.length < minimumLength) {
            return pinShortLengthWarning
        } else if (maximumLength > 0 && pinInput.length > maximumLength) {
            return pinLengthWarning
        } else {
            return ""
        }
    }

    property QtObject _feedbackEffect
    property QtObject _voiceCallManager

    property bool enableInputMethodChange
    property bool digitInputOnly: true
    property var validator // regexp, doesn't prevent input but shows validation warning when not matching

    //% "Disallowed characters"
    property string validationWarningText: qsTrId("settings_devicelock-la-alphanumeric_validation_warning")

    property bool showDigitPad: true
    property bool inputEnabled: true
    readonly property bool _digitPadEffective: showDigitPad || emergency
    property bool pasteDisabled: false

    // applies only if new pin is requested via requestAndConfirmNewPin()
    readonly property bool _pinMismatch: (enteringNewPin && pinInput.length >= minimumLength && _newPin !== "" && _newPin !== enteredPin)
    readonly property bool _inputOrCancelEnabled: inputEnabled || showCancelButton
    // Height rule an approximation without all margins exactly. Should cover currently used device set.
    readonly property bool _twoColumnMode: pageStack.currentPage.isLandscape
                                           && keypad.visible
                                           && height < (keypad.height * 1.5 + Theme.itemSizeSmall / 2)
    readonly property int _viewHeight: pageStack.currentPage.isLandscape ? Screen.width : Screen.height

    signal pinConfirmed()
    signal pinEntryCanceled()
    signal suggestionRequested()

    function clear() {
        inputEnabled = true
        suggestionsEnabled = false
        enteredPin = ""

        // Change status messages here and not when confirm button is clicked, else they may update
        // while the page is undergoing a pop transition when the PIN is confirmed.
        _overridingTitleText = _pinConfirmTitleText
        transientWarningText = _badPinWarning
        if (enteringNewPin && _pinConfirmTitleText === "") {
            enteringNewPin = false
        }
    }

    function suggestPin(pin) {
        enteredPin = pin
        pinInput.selectAll()
    }

    // Delays emission of pinConfirmed() until the same PIN has been entered twice.
    // Also changes the title text to 'Enter new PIN' and 'Re-enter new PIN' as necessary.
    // If 'oldPin' is provided, the user is not allowed to enter this value as the new PIN.
    function requestAndConfirmNewPin(oldPin) {
        _oldPin = oldPin || ""
        _pinConfirmTitleText = enterNewPinText
        enteringNewPin = true
        clear()
    }

    function focusIn() {
        // Just ensure local focus.
        pinInput.focus = true
        focus = true
    }

    function _clickedConfirmButton() {
        if (enteringNewPin) {
            // extra protection for hw keyboard enter
            if (enteredPin.length < minimumLength)
                return

            if (_newPin === "") {
                _pinConfirmTitleText = confirmNewPinText
                _badPinWarning = ""
                _newPin = enteredPin
                clear()
            } else {
                if (enteredPin === _newPin) {
                    pinConfirmed()
                    _newPin = ""
                    _badPinWarning = ""
                    _pinConfirmTitleText = ""
                } else {
                    _badPinWarning = pinMismatchText
                    _pinConfirmTitleText = confirmNewPinText
                    _newPin = ""
                    clear()
                }
            }
        } else {
            pinConfirmed()
        }
    }

    function _popPinCharacter() {
        if (suggestionVisible) {
            pinInput.remove(pinInput.selectionStart, pinInput.selectionEnd)
        } else {
            pinInput.remove(pinInput.length - 1, pinInput.length)
        }
    }

    function _handleInputKeyPress(character) {
        if (root.suggestionVisible && !root.emergency) {
            pinInput.remove(pinInput.selectionStart, pinInput.selectionEnd)
        }
        pinInput.cursorPosition = pinInput.length
        pinInput.insert(pinInput.cursorPosition, character)
    }

    function _handleCancelPress() {
        if (root.emergency) {
            root._resetView()
        } else {
            root.pinEntryCanceled()
        }
    }

    function _feedback() {
        if (_feedbackEffect) {
            _feedbackEffect.play()
        }
    }

    width: parent.width
    height: parent.height

    focus: true

    onEmergencyChanged: {
        if (!emergency) {
            _emergencyWarningText = ""
            pinInput.forceActiveFocus()
        }
    }

    onVisibleChanged: {
        if (!visible) {
            // Hiding the keyboard will remove focus from the pinInput.  Fixup the internal
            // state when the hidden so the keyboard comes back when shown again.
            pinInput.focus = true
        }
    }

    // virtual keyboard swipe down removes the focus, click anywhere to bring it back easily
    MouseArea {
        anchors.fill: parent
        onClicked: {
            pinInput.focus = true
        }
    }

    Rectangle {
        // emergency background
        color: "#4c0000"
        anchors.fill: parent
        opacity: root.emergency ? 1.0 : 0.0
        Behavior on opacity { FadeAnimation {} }
    }

    Image {
        anchors {
            horizontalCenter: headingColumn.horizontalCenter
            bottom: headingColumn.top
            bottomMargin: Theme.paddingLarge
        }
        visible: !root._inputOrCancelEnabled && !root.emergency

        source: "image://theme/icon-m-device-lock?" + headingLabel.color
    }

    // extra close button if the keypad isn't shown
    IconButton {
        id: closeButton

        anchors {
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            top: parent.top
            topMargin: Math.max(Theme.paddingMedium, root.headingVerticalOffset + Theme.paddingSmall)
        }
        enabled: !_digitPadEffective && showCancelButton
        opacity: enabled ? 1 : 0
        visible: opacity > 0
        icon.source: "image://theme/icon-m-clear"

        Behavior on opacity { FadeAnimation {} }

        onClicked: {
            if (_feedbackEffect) {
                _feedbackEffect.play()
            }
            root.pinEntryCanceled()
        }
    }

    IconButton {
        id: inputMethodSwitch

        anchors {
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
            top: parent.top
            topMargin: Math.max(Theme.paddingMedium, root.headingVerticalOffset + Theme.paddingSmall)
        }
        enabled: root.enableInputMethodChange && !root.emergency
        opacity: enabled ? 1 : 0
        visible: opacity > 0
        icon.source: root.showDigitPad ? "image://theme/icon-m-keyboard"
                                       : "image://theme/icon-m-dialpad"

        Behavior on opacity { FadeAnimation {} }

        onClicked: {
            if (_feedbackEffect) {
                _feedbackEffect.play()
            }
            root.showDigitPad = !root.showDigitPad
            if (root.showDigitPad) {
                pinInput.forceTextVisible = false
            }
        }
    }

    Column {
        id: headingColumn

        property int availableSpace: pinInput.y - headingVerticalOffset
        property bool tight: pageStack.currentPage.isLandscape && Screen.width < 1.5 * keypad.height

        y: root._inputOrCancelEnabled || root.emergency
           ? availableSpace/4 + headingVerticalOffset
           : (parent.height / 2) - headingLabel.height - subHeadingLabel.height
        x: inputMethodSwitch.enabled ? (inputMethodSwitch.x + inputMethodSwitch.width + Theme.paddingMedium)
                                     : Theme.horizontalPageMargin
        width: (root._twoColumnMode ? parent.width / 2 : parent.width)
               - x
               - (root._twoColumnMode ? Theme.paddingLarge : x)
        spacing: tight ? Theme.paddingSmall : Theme.paddingMedium

        Label {
            id: headingLabel

            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            color: root.emergency
                   ? root.emergencyTextColor
                   : root.highlightTitle
                     ? Theme.secondaryHighlightColor
                     : root.titleColor
            font.pixelSize: headingColumn.tight ? Theme.fontSizeLarge : Theme.fontSizeExtraLarge
            text: root.emergency
                      //: Shown when user has chosen emergency call mode
                      //% "Emergency call"
                    ? qsTrId("settings_pin-la-emergency_call")
                    : (root._overridingTitleText !== "" ? root._overridingTitleText : root.titleText)
        }

        Label {
            id: subHeadingLabel

            width: parent.width
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            color: headingLabel.color
            visible: text !== "" || !headingColumn.tight
            font.pixelSize: headingColumn.tight ? Theme.fontSizeMedium : Theme.fontSizeLarge
            text: root.subTitleText
        }

        Label {
            width: parent.width
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            color: root.warningTextColor
            visible: text !== ""

            font.pixelSize: root._inputOrCancelEnabled || headingColumn.tight ? Theme.fontSizeSmall : Theme.fontSizeMedium
            text: {
                if (root.emergency) {
                    return root._emergencyWarningText
                } else if (root.transientWarningText !== "") {
                    return root.transientWarningText
                } else if (root._pinValidationWarningText !== "") {
                    return root._pinValidationWarningText
                } else if (root.validator && !root.validator.test(root.enteredPin)) {
                    return root.validationWarningText
                } else {
                    return root.warningText
                }
            }
        }
    }

    BusyIndicator {
        y: headingColumn.y + headingLabel.height + ((pinInput.y - headingColumn.y - headingLabel.height - height) / 2)
        running: root.busy
        visible: running
        anchors.horizontalCenter: headingColumn.horizontalCenter
        size: BusyIndicatorSize.Medium
    }

    TextInput {
        id: pinInput

        // special property for the virtual keyboard to handle
        property var __inputMethodExtensions: { "pasteDisabled": root.pasteDisabled, 'keyboardClosingDisabled': true }
        property bool forceTextVisible
        readonly property bool interactive: root.emergency || (root.inputEnabled
                && root.requirePin
                && !(root.suggestionsEnabled && root.suggestionsEnforced && root.suggestionVisible))

        x: Theme.horizontalPageMargin
        // two column always with keypad on the right
        y: root._twoColumnMode ? root._viewHeight * 0.75 - height
                               : Math.min(((pageStack.currentPage.isPortrait || keypad.visible)
                                           ? keypad.y : root._viewHeight),
                                          (root._viewHeight
                                           - (pageStack.currentPage.isPortrait ? Qt.inputMethod.keyboardRectangle.height
                                                                               : Qt.inputMethod.keyboardRectangle.width)))
                                 - height - (pageStack.currentPage.isLandscape ? 0 : Theme.paddingLarge)
                                 - Theme.itemSizeSmall

        width: backspace.x - x - Theme.paddingSmall

        horizontalAlignment: Text.AlignRight

        focus: true
        // avoid virtual keyboard
        readOnly: root._digitPadEffective
        onReadOnlyChanged: {
            if (!readOnly) {
                Qt.inputMethod.show()
            }
        }

        enabled: interactive

        echoMode: root.emergency || forceTextVisible || (root.suggestionsEnabled && root.suggestionVisible)
                  ? TextInput.Normal
                  : TextInput.Password
        passwordCharacter: "\u2022"
        passwordMaskDelay: 1000
        cursorDelegate: Item {}

        selectionColor: "transparent"
        selectedTextColor: color

        persistentSelection: true

        color: root.emergency ? "white" : root.pinDisplayColor
        font.pixelSize: Theme.fontSizeHuge
        inputMethodHints: Qt.ImhNoPredictiveText
                          | Qt.ImhSensitiveData
                          | Qt.ImhNoAutoUppercase
                          | Qt.ImhHiddenText
                          | Qt.ImhMultiLine // This stops the text input hiding the keyboard when enter is pressed.

        EnterKey.enabled: root._validInput
        EnterKey.iconSource: "image://theme/icon-m-enter-accept"

        onTextChanged: root.transientWarningText = ""

        onAccepted: root._clickedConfirmButton()

        validator: RegExpValidator {
            regExp: {
                if (root.emergency || root.digitInputOnly) {
                    return /[0-9]*/
                } else {
                    return  /.*/
                }
            }
        }

        // readOnly property disables all key handling except return for accepting.
        // have some explicit handling here. also disallows moving the invisible cursor which is nice.
        Keys.onPressed: {
            if (root.pasteDisabled && event.key === Qt.Key_V && event.modifiers & Qt.ControlModifier) {
                event.accepted = true
            }

            if (!readOnly) {
                return
            }

            var text = event.text
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                // readonly fields still have acceptance handling
            } else if (event.key === Qt.Key_Escape) {
                _handleCancelPress()
            } else if (event.key === Qt.Key_Backspace) {
                _popPinCharacter()
            } else if (text.length === 1 && (!root.digitInputOnly || "0123456789".indexOf(text) >= 0)) {
                _handleInputKeyPress(text)
            }
        }

        MouseArea {
            anchors.fill: pinInput
            onClicked: pinInput.forceActiveFocus()
        }
    }

    OpacityRampEffect {
        sourceItem: pinInput

        enabled: pinInput.contentWidth > pinInput.width - (offset * pinInput.width)

        direction:  OpacityRamp.RightToLeft
        slope: 1 + 6 * pinInput.width / Screen.width
        offset: 1 - 1 / slope
    }

    IconButton {
        id: emergencyButton

        visible: deviceInfo.hasCellularVoiceCallFeature

        anchors {
            horizontalCenter: root._inputOrCancelEnabled
                              ? option1Button.horizontalCenter
                              : root.horizontalCenter
            verticalCenter: root._inputOrCancelEnabled
                    ? pinInput.verticalCenter
                    : keypad.bottom
            verticalCenterOffset: {
                if (root._inputOrCancelEnabled) {
                    return 0
                } else if (Screen.sizeCategory > Screen.Medium) {
                    return -Math.round(Theme.itemSizeExtraLarge / 2)
                } else {
                    return -Math.round(Theme.itemSizeLarge / 2)
                }
            }
        }
        states: [
            State {
                name: "twoColumn"
                when: root._twoColumnMode && root._inputOrCancelEnabled
                AnchorChanges {
                    target: emergencyButton
                    anchors.left: headingColumn.left
                    anchors.horizontalCenter: undefined
                }
            },
            State {
                name: "landscapeTight"
                when: pageStack.currentPage.isLandscape && !keypad.visible && headingColumn.tight
                AnchorChanges {
                    target: emergencyButton
                    anchors.right: closeButton.right
                    anchors.top: closeButton.visible ? closeButton.bottom : closeButton.top
                    anchors.horizontalCenter: undefined
                    anchors.verticalCenter: undefined
                }
            }
        ]

        enabled: visible && showEmergencyButton && !root.emergency && pinInput.length < 5
        opacity: enabled ? 1 : 0
        icon.source: "image://theme/icon-lockscreen-emergency-call"
        icon.color: undefined

        Behavior on opacity { FadeAnimator {} }

        onClicked: {
            root.enteredPin = ""
            root.emergency = !root.emergency
            root._feedback()
        }
    }

    IconButton {
        id: backspace

        anchors {
            horizontalCenter: option2Button.horizontalCenter
            verticalCenter: pinInput.verticalCenter
            verticalCenterOffset: Theme.paddingMedium
        }
        states: State {
            when: root._twoColumnMode
            AnchorChanges {
                target: backspace
                anchors.right: headingColumn.right
                anchors.horizontalCenter: undefined
            }
        }

        height: pinInput.height + Theme.paddingMedium // increase reactive area
        icon {
            source: !keypad.visible && false
                    ? (pinInput.forceTextVisible ? "image://theme/icon-splus-hide-password"
                                                 : "image://theme/icon-splus-show-password")
                    : root._showSuggestionButton
                      ? "image://theme/icon-m-reload"
                      : "image://theme/icon-m-backspace-keypad"
            color: {
                if (root.emergency) {
                    return Theme.lightPrimaryColor
                } else if (!root.dimmerBackspace) {
                    return Theme.primaryColor
                } else if (Theme.colorScheme == Theme.LightOnDark) {
                    return Theme.highlightDimmerColor
                } else {
                    return Theme.lightPrimaryColor
                }
            }
            highlightColor: root.emergency ? emergencyTextColor : Theme.highlightColor
        }

        opacity: keypad.visible && (root.enteredPin !== "" || root._showSuggestionButton)
                 ? 1 : 0
        enabled: opacity

        Behavior on opacity { FadeAnimation {} }

        onClicked: {
            if (!keypad.visible) {
                pinInput.forceTextVisible = !pinInput.forceTextVisible
            } else if (root._showSuggestionButton) {
                 root.suggestionRequested()
            } else {
                root._popPinCharacter()
            }
        }
        onPressAndHold: {
            if (!keypad.visible || root._showSuggestionButton) {
                return
            }
            root._popPinCharacter()
            if (pinInput.length > 0) {
                backspaceRepeat.start()
            }
        }
        onExited: {
            backspaceRepeat.stop()
        }
        onReleased: {
            backspaceRepeat.stop()
        }
        onCanceled: {
            backspaceRepeat.stop()
        }
    }

    IconButton {
        anchors.centerIn: backspace
        height: backspace.height
        opacity: keypad.visible ? 0 : 1
        enabled: opacity > 0
        Behavior on opacity { FadeAnimation {} }

        icon.source: pinInput.forceTextVisible ? "image://theme/icon-splus-hide-password"
                                               : "image://theme/icon-splus-show-password"
        onClicked: pinInput.forceTextVisible = !pinInput.forceTextVisible
    }

    Timer {
        id: backspaceRepeat

        interval: 150
        repeat: true

        onTriggered: {
            root._popPinCharacter()
            if (pinInput.length === 0) {
                stop()
            }
        }
    }

    Keypad {
        id: keypad

        y: root.height + pageStack.panelSize - height
           - (pageStack.currentPage.isPortrait ? Math.round(Screen.height / 20)
                                               : Theme.paddingLarge)

        anchors.right: parent.right
        width: root._twoColumnMode ? parent.width / 2 : parent.width

        symbolsVisible: false
        visible: opacity > 0
        opacity: root.requirePin
                 && root._digitPadEffective
                 ? 1 : 0
        textColor: {
            if (root.emergency) {
                return Theme.lightPrimaryColor
            } else if (pinInput.interactive) {
                return root.keypadTextColor
            } else {
                return Theme.highlightColor
            }
        }

        pressedTextColor: root.emergency ? "black" : (Theme.colorScheme === Theme.LightOnDark ? Theme.highlightColor : Theme.highlightDimmerColor)
        pressedButtonColor: root.emergency
                            ? emergencyTextColor
                            : Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)

        secondaryTextColor: root.emergency ? Theme.lightSecondaryColor : root.keypadSecondaryTextColor
        pressedSecondaryTextColor: root.emergency ? Theme.darkSecondaryColor : palette.secondaryHighlightColor

        enabled: pinInput.activeFocus
        onPressed:  {
            root._feedback()
            _handleInputKeyPress(number)
        }
    }

    PinInputOptionButton {
        id: option1Button

        visible: (keypad.visible || !root.requirePin)
                 && (showCancelButton || root.emergency)

        anchors {
            left: keypad.left
            leftMargin: keypad._horizontalPadding
            bottom: keypad.bottom
            bottomMargin: icon.visible ? 0 : (keypad._buttonHeight - height) / 2
        }
        primaryColor: keypad.textColor
        width: keypad._buttonWidth
        height: icon.visible ? keypad._buttonHeight : width / 2
        emergency: root.emergency
        text: root.emergency
              ? //: Cancels out of the emergency call mode and returns to the PIN input screen
                //% "Cancel"
                qsTrId("settings_pin-bt-cancel_emergency_call")
              : ""

        icon {
            visible: !root.emergency
            source: "image://theme/icon-m-cancel"
        }

        onClicked: {
            root._feedback()
            _handleCancelPress()
        }
    }

    PinInputOptionButton {
        id: option2Button

        property bool showIcon: !root.emergency
                                && (!root.requirePin
                                    || (root._validInput
                                        && !root._pinMismatch
                                        && (!root.enteringNewPin || root._oldPin == "" || root._oldPin !== root.enteredPin)))

        primaryColor: option1Button.primaryColor
        visible: (keypad.visible || !root.requirePin)
                 && (text !== "" || showIcon)
                 && ((root.showOkButton && root.inputEnabled) || root.emergency)

        anchors {
            right: keypad.right
            rightMargin: keypad._horizontalPadding
            bottom: keypad.bottom
            bottomMargin: icon.visible ? 0 : (keypad._buttonHeight - height) / 2
        }
        width: option1Button.width
        height: icon.visible ? keypad._buttonHeight : width / 2
        emergency: root.emergency
        text: root.emergency ? //: Starts the phone call
                               //% "Call"
                               qsTrId("settings_pin-bt-start_call")
                             : ""
        showWhiteBackgroundByDefault: root.emergency
        icon {
            visible: showIcon
            source: "image://theme/icon-m-accept"
        }

        onClicked: {
            root._feedback()
            if (root.emergency) {
                root._dialEmergencyNumber()
            } else {
                root._clickedConfirmButton()
            }
        }
    }

    OfonoModemManager { id: modemManager }
    OfonoManager { id: manager }

    OfonoModem {
        id: modem
        modemPath: root.modemPath
    }

    OfonoVoiceCallManager {
        id: voiceCallManager
        modemPath: root.modemPath
    }

    // To make an emergency call: (as per ofono emergency-call-handling.txt)
    // 1) Set org.ofono.Modem online=true
    // 2) Dial number using telephony VoiceCallManager
    function _dialEmergencyNumber() {
        root._emergencyWarningText = ""
        if (!modem.online) {
            modem.onlineChanged.connect(_dialEmergencyNumber)
            modem.online = true
            return
        }
        modem.onlineChanged.disconnect(_dialEmergencyNumber)
        var emergencyNumbers = voiceCallManager.emergencyNumbers
        if (root.enteredPin !== "" && emergencyNumbers.indexOf(root.enteredPin) === -1) {
            //: Indicates that user has entered invalid emergency number
            //% "Only emergency calls permitted"
            root._emergencyWarningText = qsTrId("settings_pin-la-invalid_emergency_number")
            return
        }

        // If no number has been entered,
        // prefill emergency number with GSM standard "112"
        if (root.enteredPin === "") {
            var emergencyNumber = "112"
            for (var i=0; i<emergencyNumber.length; i++) {
                _pushPinDigit(emergencyNumber[i])
            }
        }
        if (!_voiceCallManager) {
            _voiceCallManager = Qt.createQmlObject("import QtQuick 2.0; import org.nemomobile.voicecall 1.0; VoiceCallManager {}",
                               root, 'VoiceCallManager');
            _voiceCallManager.modemPath = Qt.binding(function() { return root.modemPath })
        }
        _voiceCallManager.dial(root.enteredPin)
    }

    function _resetView() {
        enteredPin = ""
        emergency = false
    }

    // Reset view on Device lock & start up pinquery
    Connections {
        target: Lipstick.compositor
        onHomeActiveChanged: if (!Lipstick.compositor.homeActive) delayReset.start()
    }

    // Reset view on pinquery when viewed from settings/applications.
    Connections {
        target: Qt.application
        onActiveChanged: if (Qt.application.active) delayReset.start()
    }

    DeviceInfo {
        id: deviceInfo
        readonly property bool hasCellularVoiceCallFeature: hasFeature(DeviceInfo.FeatureCellularVoice)
    }

    Timer {
        id: delayReset
        interval: 250
        onTriggered: root._resetView()
    }

    Component.onCompleted: {
        // Avoid hard dependency to feedback
        _feedbackEffect = Qt.createQmlObject("import QtQuick 2.0; import QtFeedback 5.0; ThemeEffect { effect: ThemeEffect.PressWeak }",
                           root, 'ThemeEffect');
    }
}
