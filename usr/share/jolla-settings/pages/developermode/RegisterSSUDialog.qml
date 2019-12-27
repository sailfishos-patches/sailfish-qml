import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: registerSSUDialog
    canAccept: usernameField.text.length > 0 && passwordField.text.length > 0

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
                acceptText: qsTrId("settings_developermode-bu-login")
            }

            TextField {
                id: usernameField

                //% "Username"
                placeholderText: qsTrId("settings_developermode-ph-username")

                //% "Username"
                label: qsTrId("settings_developermode-lb-username")

                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                width: parent.width
                focus: true

                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.enabled: text != ""
                EnterKey.highlighted: text != ""
                EnterKey.onClicked: passwordField.forceActiveFocus()
            }

            PasswordField {
                id: passwordField

                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.enabled: text != ""
                EnterKey.highlighted: text != ""
                EnterKey.onClicked: registerSSUDialog.accept()
            }

            TextField {
                id: domainField

                //% "SSU Domain"
                placeholderText: qsTrId("settings_developermode-ph-domain")

                //% "SSU Domain"
                label: qsTrId("settings_developermode-lb-domain")

                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                width: parent.width

                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.highlighted: text != ""
                EnterKey.onClicked: registerSSUDialog.accept()
            }
        }
    }
}
