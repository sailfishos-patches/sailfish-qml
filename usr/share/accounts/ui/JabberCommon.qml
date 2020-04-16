import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.accounts 1.0

Column {
    property bool editMode
    property bool usernameEdited
    property bool passwordEdited
    property bool acceptAttempted
    property alias username: usernameField.text
    property alias password: passwordField.text
    property alias server: serverField.text
    property alias ignoreSslErrors: ignoreSslErrors.checked
    property alias port: portField.text
    property alias priority: priorityField.text
    property bool acceptableInput: username != "" && password != "" && priorityField.acceptableInput

    width: parent.width

    TextField {
        id: usernameField
        visible: !editMode
        width: parent.width
        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        errorHighlight: !text && acceptAttempted

        //: Placeholder text for XMPP username
        //% "Enter username"
        placeholderText: qsTrId("components_accounts-ph-jabber_username_placeholder")
        //: XMPP username
        //% "Username"
        label: qsTrId("components_accounts-la-jabber_username")
        onTextChanged: {
            if (focus) {
                usernameEdited = true
                // Updating username also updates password; clear it if it's default value
                if (!passwordEdited)
                    passwordField.text = ""
            }
        }
        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: passwordField.focus = true
    }

    PasswordField {
        id: passwordField
        visible: !editMode
        errorHighlight: !text && acceptAttempted

        //: Placeholder text for password
        //% "Enter password"
        placeholderText: qsTrId("components_accounts-ph-jabber_password_placeholder")
        onTextChanged: {
            if (focus && !passwordEdited) {
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
        width: parent.width
        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        //: Placeholder text for XMPP server address
        //% "Enter server address (Optional)"
        placeholderText: qsTrId("components_accounts-ph-jabber_server_placeholder")
        //: XMPP server address
        //% "Server address"
        label: qsTrId("components_accounts-la-jabber_server")
        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: portField.focus = true
    }

    TextField {
        id: portField
        width: parent.width
        inputMethodHints: Qt.ImhDigitsOnly
        //: Placeholder text for XMPP server port
        //% "Enter port"
        placeholderText: qsTrId("components_accounts-ph-jabber_port_placeholder")
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
        width: parent.width
        inputMethodHints: Qt.ImhDigitsOnly
        //: Placeholder text for XMPP client priority
        //% "Enter priority"
        placeholderText: qsTrId("components_accounts-ph-jabber_priority_placeholder")
        //% "Priority"
        label: qsTrId("components_accounts-la-jabber_priority")
        text: "0"
        validator: IntValidator { bottom: -127; top: 128 }
        EnterKey.iconSource: "image://theme/icon-m-enter-close"
        EnterKey.onClicked: focus = false
    }
}
