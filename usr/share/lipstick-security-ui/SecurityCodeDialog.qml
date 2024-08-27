import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.devicelock 1.0

PasswordInputDialog {
    id: input

    property AuthenticationInput agent
    property alias securityCode: input.password
    property alias requireSecurityCode: input.requirePassword

    function suggestSecurityCode(code) {
        suggestPassword(code)
    }

    suggestionsEnforced: agent.codeGeneration === AuthenticationInput.MandatoryCodeGeneration

    titleText: feedbackHandler.acceptTitle
    okText: feedbackHandler.confirmText
    okButtonVisible: agent.status === AuthenticationInput.Authenticating

    minimumLength: agent.minimumCodeLength
    maximumLength: agent.maximumCodeLength
    alphanumericToggleEnabled: true
    digitsOnly: true
    passwordMaskDelay: 0

    onConfirmed: {
        feedbackHandler.submitted = true
        if (input.requirePassword) {
            agent.enterSecurityCode(password)
        } else {
            agent.authorize()
        }
    }
    onCanceled: {
        agent.cancel()
    }

    onSuggestionRequested: {
        agent.requestSecurityCode()
    }

    Connections {
        target: input.agent
        onShow: input.activate()
        onHide: input.dismiss()
    }

    DeviceLockFeedback {
        id: feedbackHandler

        agent: input.agent
        ui: input
    }
}
