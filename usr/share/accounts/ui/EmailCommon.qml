/*
 * Copyright (c) 2013 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.accounts 1.0

Column {
    id: root

    property bool editMode
    property bool hideIncoming
    property bool hideOutgoing
    property bool incomingUsernameEdited
    property bool incomingPasswordEdited
    property bool outgoingUsernameEdited
    property bool outgoingPasswordEdited
    property bool checkMandatoryFields
    property bool accountLimited
    property alias emailAddress: emailaddress.text
    property alias serverTypeIndex: incomingServerType.currentIndex
    property alias incomingUsername: incomingUsernameField.text
    property alias incomingPassword: incomingPasswordField.text
    property alias incomingServer: incomingServerField.text
    property alias incomingSecureConnectionIndex: incomingSecureConnection.currentIndex
    property alias incomingPort: incomingPortField.text
    property alias outgoingUsername: outgoingUsernameField.text
    property alias outgoingPassword: outgoingPasswordField.text
    property alias outgoingServer: outgoingServerField.text
    property alias outgoingSecureConnectionIndex: outgoingSecureConnection.currentIndex
    property alias outgoingPort: outgoingPortField.text
    property alias outgoingRequiresAuth: outgoingRequiresAuthSwitch.checked
    property alias acceptUntrustedCertificates: acceptUntrustedCertificatesSwitch.checked

    spacing: Theme.paddingLarge
    width: parent.width

    function defaultIncomingPort() {
        if (serverTypeIndex === 0) {
            if (incomingSecureConnectionIndex === 1) {
                return "993"
            } else {
                return "143"
            }
        } else {
            if (incomingSecureConnectionIndex === 1) {
                return "995"
            } else {
                return "110"
            }
        }
    }

    function defaultOutgoingPort() {
        if (outgoingSecureConnectionIndex === 1) {
            return "465"
        } else if (outgoingSecureConnectionIndex === 2) {
            return "587"
        } else {
            return "25"
        }
    }

    GeneralEmailAddressField {
        id: emailaddress
        visible: !accountLimited
        onTextChanged: {
            if (!incomingUsernameEdited && !editMode) {
                incomingUsernameField.text = text
            }
        }
        errorHighlight: !text && checkMandatoryFields
        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: incomingUsernameField.focus = true
    }

    SectionHeader {
        id: incomingServerSection
        visible: !hideIncoming
        //: Label explaining that the following fields are for the incoming mail server
        //% "Incoming mail server"
        text: qsTrId("components_accounts-la-genericemail_incoming_server_label")
    }

    ComboBox {
        id: incomingServerType
        visible: !editMode && !hideIncoming && !accountLimited
        width: parent.width - Theme.paddingMedium
        //: Incoming server type
        //% "Server type"
        label: qsTrId("components_accounts-la-genericemail_incoming_server_type")
        currentIndex: 0

        menu: ContextMenu {
            MenuItem { text: "IMAP4" }
            MenuItem { text: "POP3" }
            onClosed: incomingUsernameField.focus = true
        }
    }

    TextField {
        id: incomingUsernameField
        visible: !hideIncoming && !accountLimited
        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        //: Incoming server username
        //% "Username"
        label: qsTrId("components_accounts-la-genericemail_incoming_username")
        onTextChanged: {
            if (focus) {
                incomingUsernameEdited = true
            }
            if (!outgoingUsernameEdited && !editMode) {
                outgoingUsernameField.text = text
            }
        }
        //% "Username is required"
        description: errorHighlight ? qsTrId("components_accounts-la-username_required") : ""

        errorHighlight: !text && checkMandatoryFields
        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: incomingPasswordField.focus = true
    }

    PasswordField {
        id: incomingPasswordField
        visible: !hideIncoming
        onTextChanged: {
            if (focus && !incomingPasswordEdited) {
                incomingPasswordEdited = true
            }
            if (!outgoingPasswordEdited && !editMode) {
                outgoingPasswordField.text = text
            }
        }
        //% "Password is required"
        description: errorHighlight ? qsTrId("components_accounts-la-password_required") : ""

        errorHighlight: !text && checkMandatoryFields
        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: incomingServerField.focus = true
    }

    TextField {
        id: incomingServerField
        visible: !hideIncoming && !accountLimited
        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        //: Incoming server address
        //% "Server address"
        label: qsTrId("components_accounts-la-genericemail_incoming_server")

        //% "Server address is required"
        description: errorHighlight ? qsTrId("components_accounts-la-server_address_required") : ""

        errorHighlight: !text && checkMandatoryFields
        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: incomingPortField.focus = true
    }

    ComboBox {
        id: incomingSecureConnection
        visible: !hideIncoming && !accountLimited
        width: parent.width - Theme.paddingMedium
        //: Incoming server secure connection
        //% "Secure connection"
        label: qsTrId("components_accounts-la-genericemail_incoming_secure_connection")
        currentIndex: 0

        menu: ContextMenu {
            MenuItem {
                //% "None"
                text: qsTrId("components_accounts-la-genericemail_secure_connection_none")
            }
            MenuItem { text: "SSL" }
            MenuItem { text: "StartTLS" }
            onClosed: outgoingServerField.focus = true
        }
    }

    TextField {
        id: incomingPortField
        visible: !hideIncoming && !accountLimited
        inputMethodHints: Qt.ImhDigitsOnly
        //: Incoming server port
        //% "Port"
        label: qsTrId("components_accounts-la-genericemail_incoming_port")
        text: defaultIncomingPort()
        errorHighlight: !text && checkMandatoryFields

        //% "Port is required"
        description: errorHighlight ? qsTrId("components_accounts-la-port_required") : ""

        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: outgoingServerField.focus = true
    }

    SectionHeader {
        id: outgoingServerSection
        visible: !hideOutgoing && !accountLimited && outgoingPasswordField.visible
        //: Label explaining that the following fields are for the outgoing mail server
        //% "Outgoing mail server"
        text: qsTrId("components_accounts-la-genericemail_outgoing_server_label")
    }

    ComboBox {
        id: outgoingServerType
        visible: !editMode && !hideOutgoing && !accountLimited
        width: parent.width
        //: Outgoing server type
        //% "Server type"
        label: qsTrId("components_accounts-la-genericemail_outgoing_server_type")
        currentIndex: 0

        menu: ContextMenu {
            MenuItem { text: "SMTP" } // we only support SMTP at this time
            onClosed: outgoingServerField.focus = true
        }
    }

    TextField {
        id: outgoingServerField
        visible: !hideOutgoing && !accountLimited
        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        //: Outgoing server address
        //% "Server address"
        label: qsTrId("components_accounts-la-genericemail_outgoing_server")
        errorHighlight: !text && checkMandatoryFields

        //% "Server address is required"
        description: errorHighlight ? qsTrId("components_accounts-la-server_address_required") : ""

        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: outgoingPortField.focus = true
    }

    ComboBox {
        id: outgoingSecureConnection
        visible: !hideOutgoing && !accountLimited
        width: parent.width - Theme.paddingMedium
        //: Outgoing server secure connection
        //% "Secure connection"
        label: qsTrId("components_accounts-la-genericemail_outgoing_secure_connection")
        currentIndex: 0

        menu: ContextMenu {
            MenuItem {
                text: qsTrId("components_accounts-la-genericemail_secure_connection_none")
            }
            MenuItem { text: "SSL" }
            MenuItem { text: "StartTLS" }
        }
    }

    TextField {
        id: outgoingPortField
        visible: !hideOutgoing && !accountLimited
        inputMethodHints: Qt.ImhDigitsOnly
        //: Outgoing server port
        //% "Port"
        label: qsTrId("components_accounts-la-genericemail_outgoing_port")
        text: defaultOutgoingPort()
        errorHighlight: !text && checkMandatoryFields

        //% "Port is required"
        description: errorHighlight ? qsTrId("components_accounts-la-port_required") : ""

        EnterKey.iconSource: "image://theme/icon-m-enter-close"
        EnterKey.onClicked: outgoingUsernameField.visible ? outgoingUsernameField.focus = true : focus = false
    }

    TextSwitch {
        id: outgoingRequiresAuthSwitch
        visible: !hideOutgoing && !accountLimited
        checked: true
        //% "Requires authentication"
        text: qsTrId("components_accounts-la-genericemail_outgoing_requires_auth")
    }

    TextField {
        id: outgoingUsernameField
        visible: !hideOutgoing && outgoingRequiresAuthSwitch.checked && !accountLimited
        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        //% "Username"
        label: qsTrId("components_accounts-la-genericemail_outgoing_username")
        errorHighlight: !text && checkMandatoryFields
        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: outgoingPasswordField.focus = true

        //% "Username is required"
        description: errorHighlight ? qsTrId("components_accounts-la-username_required") : ""

        // solution for faster input, since most accounts have same credentials for
        // username and password
        // this can go away if we get a initial page for username/password, depends on design
        onTextChanged: {
            if (focus)
                outgoingUsernameEdited = true
        }
    }

    PasswordField {
        id: outgoingPasswordField
        visible: !hideOutgoing && outgoingRequiresAuthSwitch.checked
        errorHighlight: !text && checkMandatoryFields
        onTextChanged: if (focus) outgoingPasswordEdited = true

        //% "Password is required"
        description: errorHighlight ? qsTrId("components_accounts-la-password_required") : ""

        EnterKey.iconSource: "image://theme/icon-m-enter-accept"
        EnterKey.onClicked: root.focus = true
    }

    SectionHeader {
        id: certificatesSection
        visible: !accountLimited
        //: Label explaining that the following fields are related to server certificates
        //% "Certificates"
        text: qsTrId("components_accounts-la-genericemail_certificates_label")
    }

    TextSwitch {
        id: acceptUntrustedCertificatesSwitch
        visible: !accountLimited
        checked: false
        //: Accept untrusted certificates
        //% "Accept untrusted certificates"
        text: qsTrId("components_accounts-la-genericemail_accept_certificates")
        //: Description informing the user that accepting untrusted certificates can poses potential security threats
        //% "Accepting untrusted certificates poses potential security threats to your data."
        description: qsTrId("components_accounts-la-genericemail_accept_certificates_description")
    }
}
