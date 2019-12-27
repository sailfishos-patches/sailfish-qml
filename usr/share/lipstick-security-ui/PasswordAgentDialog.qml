import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import Sailfish.Lipstick.Security 1.0

PasswordInputDialog {
    id: window

    property PasswordAgent agent

    titleText: agent.message

    minimumLength: agent.minimumLength
    maximumLength: agent.maximumLength

    echoMode: agent.echo === PasswordAgent.Normal
              ? TextInput.Normal
              : TextInput.Password
    passwordMaskDelay: agent.echo != PasswordAgent.Mask
            ? 1000
            : 0
    inputMethodHints: {
        switch (agent.allowedCharacters) {
        case PasswordAgent.NumericCharacters:
            return Qt.ImhDigitsOnly
        case PasswordAgent.LatinCharacters:
            return Qt.ImhLatinOnly
        default:
            return 0
        }
    }

    onPasswordChanged: agent.assessNewPassword(password)
    onConfirmed: agent.submitPassword(password)
    onCanceled: agent.cancel();

    Connections {
        target: window.agent

        onCreatePassword: {
            window.descriptionText = window.agent.enterNewPasswordText
            window.okText = window.agent.acceptNewPasswordText
            window.cancelText = window.agent.cancelNewPasswordText
            window.password = ""
            window.warningText = error
            window.focusIn()
        }
        onRepeatPassword: {
            window.descriptionText = window.agent.repeatNewPasswordText
            window.password = ""
            window.warningText = error
            window.focusIn()
        }
        onConfirmPassword: {
            window.descriptionText = window.agent.enterCurrentPasswordText
            window.okText = window.agent.acceptText
            window.cancelText = window.agent.cancelText
            window.password = ""
            window.warningText = error
            window.focusIn()
        }
        onClearPassword: {
            window.password = ""
            window.warningText = error
        }

        onShow: window.activate()
        onHide: window.dismiss()
    }
}
