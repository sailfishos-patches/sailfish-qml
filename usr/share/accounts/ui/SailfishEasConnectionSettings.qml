import QtQuick 2.0
import Sailfish.Silica 1.0

Column {
    property alias emailaddress: emailaddressField.text
    property alias username: usernameField.text
    property alias password: passwordField.text
    property alias domain: domainField.text
    property alias server: serverField.text
    property alias secureConnection: secureConnectionSwitch.checked
    property alias port: portField.text
    property alias acceptSSLCertificates: acceptSSLCertificatesSwitch.checked
    property bool passwordEdited
    property bool editMode
    property bool checkMandatoryFields

    width: parent.width

    TextField {
        id: emailaddressField
        width: parent.width
        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhEmailCharactersOnly
        //% "Email address"
        label: qsTrId("components_accounts-la-activesync_emailaddress")
        placeholderText: label
        errorHighlight: !text && checkMandatoryFields
        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: usernameField.focus = true
    }

    TextField {
        id: usernameField
        width: parent.width
        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        //: Account username
        //% "Username"
        label: qsTrId("components_accounts-la-activesync_username")
        placeholderText: label
        errorHighlight: !text && checkMandatoryFields
        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: passwordField.focus = true
    }

    PasswordField {
        id: passwordField
        width: parent.width
        onTextChanged: {
            if (focus && !passwordEdited) {
                passwordEdited = true
            }
        }
        errorHighlight: !text && checkMandatoryFields
        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: domainField.focus = true
    }

    SectionHeader {
        //% "Server"
        text: qsTrId("components_accounts-he-server")
    }

    TextField {
        id: domainField
        width: parent.width
        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        //% "Domain"
        label: qsTrId("components_accounts-la-activesync_domain")
        placeholderText: label
        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: {
            if (editMode) {
                serverField.focus = true
            } else {
                root.focus = true
            }
        }
    }
    Column {
        clip: true
        enabled: editMode
        height: enabled ? implicitHeight : 0
        opacity: enabled ? 1.0 : 0.0
        width: parent.width
        Behavior on height { NumberAnimation { easing.type: Easing.InOutQuad; duration: 400 } }
        Behavior on opacity { FadeAnimation { duration: 400 } }

        TextField {
            id: serverField
            width: parent.width
            inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
            //% "Address"
            label: qsTrId("components_accounts-la-activesync_server_address")
            placeholderText: label
            errorHighlight: !text && checkMandatoryFields
            EnterKey.iconSource: "image://theme/icon-m-enter-next"
            EnterKey.onClicked: portField.focus = true
        }

        TextField {
            id: portField
            width: parent.width
            inputMethodHints: Qt.ImhDigitsOnly
            //: Server port
            //% "Port"
            label: qsTrId("components_accounts-la-activesync_server_port")
            placeholderText: label
            EnterKey.iconSource: "image://theme/icon-m-enter-next"
            EnterKey.onClicked: secureConnectionSwitch.focus = true
            text: secureConnection ? "443" : "80"
        }

        SectionHeader {
            //% "Security"
            text: qsTrId("components_accounts-he-security")
        }

        TextSwitch {
            id: secureConnectionSwitch
            checked: true
            //: Server secure connection
            //% "Secure connection"
            text: qsTrId("components_accounts-la-activesync_secure_connection")
        }

        TextSwitch {
            id: acceptSSLCertificatesSwitch
            checked: false
            //% "Accept untrusted certificates"
            text: qsTrId("components_accounts-la-activesync_accept_ssl_certificates")
            //: Description informing the user that accepting untrusted certificates can poses potential security threats
            //% "Accepting untrusted certificates poses potential security threats to your data."
            description: qsTrId("components_accounts-la-activesync_accept_ssl_certificates_description")
        }
    }
}
