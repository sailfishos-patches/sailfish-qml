import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: registerSSUDialog
    canAccept: usernameField.acceptableInput && passwordField.acceptableInput
    onAcceptBlocked: {
        if (!usernameField.acceptableInput) {
            usernameField.errorHighlight = true
        }

        if (!passwordField.acceptableInput) {
            passwordField.errorHighlight = true
        }
    }

    property alias domain: domainField.text
    property alias username: usernameField.text
    property alias password: passwordField.text

    SilicaFlickable {
        anchors.fill: parent

        contentHeight: loginBoxColumn.height + Theme.paddingLarge

        Column {
            id: loginBoxColumn

            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                //% "Login"
                acceptText: qsTrId("settings_developermode-bt-login")
            }

            TextField {
                id: usernameField

                //% "Username"
                label: qsTrId("settings_developermode-la-username")

                acceptableInput: text.length > 0
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                width: parent.width
                focus: true

                //% "Username is required"
                description: errorHighlight ? qsTrId("settings_developermode-la-username_required") : ""

                onAcceptableInputChanged: if (acceptableInput) errorHighlight = false
                onActiveFocusChanged: if (!activeFocus) errorHighlight = !acceptableInput

                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.enabled: text != ""
                EnterKey.highlighted: text != ""
                EnterKey.onClicked: passwordField.forceActiveFocus()
            }

            PasswordField {
                id: passwordField

                //% "Password is required"
                description: errorHighlight ? qsTrId("settings_developermode-la-password_required") : ""
                acceptableInput: text.length > 0

                onAcceptableInputChanged: if (acceptableInput) errorHighlight = false
                onActiveFocusChanged: if (!activeFocus) errorHighlight = !acceptableInput

                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.enabled: text != ""
                EnterKey.highlighted: text != ""
                EnterKey.onClicked: registerSSUDialog.accept()
            }

            TextField {
                id: domainField

                //% "SSU Domain"
                label: qsTrId("settings_developermode-la-domain")

                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.highlighted: text != ""
                EnterKey.onClicked: registerSSUDialog.accept()
            }
        }
    }
}
