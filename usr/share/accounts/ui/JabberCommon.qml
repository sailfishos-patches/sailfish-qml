import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.accounts 1.0

Column {
    property bool editMode
    property bool usernameEdited
    property bool passwordEdited
    property alias username: usernameField.text
    property alias password: passwordField.text
    property alias server: serverField.text
    property alias ignoreSslErrors: ignoreSslErrors.checked
    property alias port: portField.text
    property alias priority: priorityField.text
    property bool acceptableInput: usernameField.acceptableInput && passwordField.acceptableInput && priorityField.acceptableInput

    signal acceptBlocked

    onAcceptBlocked: {
        if (!usernameField.acceptableInput) {
            usernameField.errorHighlight = true
        }

        if (!passwordField.acceptableInput) {
            passwordField.errorHighlight = true
        }
    }

    width: parent.width

    TextField {
        id: usernameField

        visible: !editMode
        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        acceptableInput: text.length > 0

        //: XMPP username
        //% "Username"
        label: qsTrId("components_accounts-la-jabber_username")

        onTextChanged: {
            if (activeFocus) {
                usernameEdited = true
                // Updating username also updates password; clear it if it's default value
                if (!passwordEdited) {
                    passwordField.text = ""
                }
            }
        }
        onAcceptableInputChanged: if (acceptableInput) errorHighlight = false
        onActiveFocusChanged: if (!activeFocus) errorHighlight = !acceptableInput

        //% "Username is required"
        description: errorHighlight ? qsTrId("settings_developermode-la-username_required") : ""

        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: passwordField.focus = true
    }

    PasswordField {
        id: passwordField

        visible: !editMode

        //% "Password is required"
        description: errorHighlight ? qsTrId("settings_developermode-la-password_required") : ""
        acceptableInput: text.length > 0

        onActiveFocusChanged: if (!activeFocus) errorHighlight = !acceptableInput
        onAcceptableInputChanged: if (acceptableInput) errorHighlight = false

        onTextChanged: {
            if (activeFocus && !passwordEdited) {
                passwordEdited = true
            }
        }

        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: serverField.focus = true
    }

    SectionHeader {
        //% "Advanced settings"
        text: qsTrId("components_accounts-la-jabber_advanced_settings_header")
    }

    TextField {
        id: serverField

        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        //: Placeholder text for XMPP server address
        //% "Server address (Optional)"
        placeholderText: qsTrId("components_accounts-ph-jabber_server_placeholder")
        //: XMPP server address
        //% "Server address"
        label: qsTrId("components_accounts-la-jabber_server")
        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: portField.focus = true
    }

    TextField {
        id: portField

        inputMethodHints: Qt.ImhDigitsOnly
        validator: IntValidator { bottom: 0; top: 65535 }

        //% "Port needs to be a value between 0 and 65535"
        description: errorHighlight ? qsTrId("settings_developermode-la-port_description") : ""

        //: XMPP server port
        //% "Port"
        label: qsTrId("components_accounts-la-jabber_port")
        text: "5222"
        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: priorityField.focus = true
    }

    TextSwitch {
        id: ignoreSslErrors
        //: Switch to ignore SSL security errors
        //% "Ignore SSL Errors"
        text: qsTrId("components_accounts-la-jabber_ignore_ssl_errors")
    }

    TextField {
        id: priorityField

        inputMethodHints: Qt.ImhDigitsOnly
        //: Placeholder text for XMPP client priority
        //% "Enter priority"
        placeholderText: qsTrId("components_accounts-ph-jabber_priority_placeholder")
        //% "Priority"
        label: qsTrId("components_accounts-la-jabber_priority")
        text: "0"
        validator: IntValidator { bottom: -127; top: 128 }

        //% "Priority needs to be a value between -127 and 128"
        description: errorHighlight ? qsTrId("settings_developermode-la-priority_description") : ""

        EnterKey.iconSource: "image://theme/icon-m-enter-close"
        EnterKey.onClicked: focus = false
    }
}
