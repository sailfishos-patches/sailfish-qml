import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.devicelock 1.0

PinInput {
    id: input

    property AuthenticationInput authenticationInput
    property alias acceptTitle: feedbackHandler.acceptTitle
    property alias confirmText: feedbackHandler.confirmText
    property alias confirmTextTitle: feedbackHandler.confirmTextTitle
    property alias enterText: feedbackHandler.enterText
    property alias enterSecurityCode: feedbackHandler.enterSecurityCode
    property alias enterNewSecurityCode: feedbackHandler.enterNewSecurityCode

    property string descriptionText
    property alias securityCode: input.enteredPin
    property alias requireSecurityCode: input.requirePin

    function suggestSecurityCode(code) {
        suggestPin(code)
    }

    titleText: feedbackHandler.acceptTitle
    subTitleText: descriptionText

    showOkButton: authenticationInput && authenticationInput.status === AuthenticationInput.Authenticating

    enabled: authenticationInput.status !== AuthenticationInput.Idle && authenticationInput.status !== AuthenticationInput.Evaluating
    busy: authenticationInput.status === AuthenticationInput.Evaluating

    minimumLength: authenticationInput ? authenticationInput.minimumCodeLength : 0
    maximumLength: authenticationInput ? authenticationInput.maximumCodeLength : 64
    digitInputOnly: false
    enableInputMethodChange: true
    suggestionsEnforced: authenticationInput && authenticationInput.codeGeneration === AuthenticationInput.MandatoryCodeGeneration
    passwordMaskDelay: 0

    warningTextColor: {
        if (emergency) {
            return Theme.primaryColor
        } else if (inputEnabled) {
            return Theme.highlightColor
        } else {
            return Theme.secondaryHighlightColor
        }
    }

    onPinConfirmed: {
        feedbackHandler.submitted = true
        authenticationInput.enterSecurityCode(enteredPin)
    }

    onPinEntryCanceled: {
        clear()
        authenticationInput.cancel()
    }

    onSuggestionRequested: authenticationInput.requestSecurityCode()

    DeviceLockFeedback {
        id: feedbackHandler
        agent: input.authenticationInput
        ui: input
    }
}
