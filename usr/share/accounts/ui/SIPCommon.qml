import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.accounts 1.0

Column {
    property alias account: accountField.text
    property alias password: passwordField.text

    property bool editMode
    property bool acceptAttempted

    property bool acceptableInput: account != "" && password != ""

    width: parent.width

    TextField {
        id: accountField

        property string _tpType: 's'
        property string _tpParam: "param-account"

        width: parent.width
        visible: !editMode

        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        errorHighlight: !text && acceptAttempted

        placeholderText: "username@sip.example.com"

        //: SIP account
        //% "Account"
        label: qsTrId("components_accounts-la-sip_account")

        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: passwordField.focus = true
    }

    TextField {
        id: passwordField

        width: parent.width
        visible: !editMode

        echoMode: TextInput.Password
        errorHighlight: !text && acceptAttempted

        //: Placeholder text for password
        //% "Enter password"
        placeholderText: qsTrId("components_accounts-ph-sip_password_placeholder")

        //: SIP password
        //% "Password"
        label: qsTrId("components_accounts-la-sip_password")

        EnterKey.iconSource: "image://theme/icon-m-enter-close"
        EnterKey.onClicked: focus = false
    }

    TextField {
        id: nicknameField

        property string _tpType: 's'
        property string _tpParam: "param-alias"

        width: parent.width

        //: Placeholder text for account alias
        //% "Enter nickname (optional)"
        placeholderText: qsTrId("components_accounts-ph-sip_alias")

        //: User Alias
        //% "Nickname"
        label: qsTrId("components_accounts-la-sip_alias")
    }

    SectionHeader {
        //% "Advanced settings"
        text: qsTrId("components_accounts-la-sip_advanced_settings-header")
    }

    ComboBox {
        id: transportField

        property string _tpType: "e"
        property string _tpParam: "param-transport"
        property string _tpDefault: 'auto'

        width:parent.width

        //% "Transport"
        label: qsTrId("components_accounts-la-sip_transport")

        menu: ContextMenu {
            MenuItem {
                property string _tpValue: "auto"

                //% "Automatic"
                text: qsTrId("components_accounts-la-sip_transport_auto")
            }
            MenuItem {
                property string _tpValue: "udp"

                text: "UDP"
            }
            MenuItem {
                property string _tpValue: "tcp"

                text: "TCP"
            }
            MenuItem {
                property string _tpValue: "tls"

                text: "TLS"
            }
        }
    }

    TextField {
        id: usernameField

        property string _tpType: 's'
        property string _tpParam: "param-auth-user"

        width: parent.width

        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

        //: Placeholder text for username override
        //% "Username"
        placeholderText: qsTrId("components_accounts-ph-sip_username")

        //: Username
        //% "Username"
        label: qsTrId("components_accounts-la-sip_username")
    }

    TextField {
        id: hostField

        property string _tpType: 's'
        property string _tpParam: "param-proxy-host"

        width: parent.width

        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

        //: Placeholder text for account server
        //% "Server"
        placeholderText: qsTrId("components_accounts-ph-sip_server")

        //: Server
        //% "Server"
        label: qsTrId("components_accounts-la-sip_server")
    }

    TextField {
        id: portField

        property string _tpType: 's'
        property string _tpParam: "param-port"

        width: parent.width

        inputMethodHints: Qt.ImhDigitsOnly

        //: Placeholder text for account port
        //% "Port"
        placeholderText: qsTrId("components_accounts-ph-sip_port")

        //: Port
        //% "Port"
        label: qsTrId("components_accounts-la-sip_port")
    }

    //TODO: VISIBLE ONLY IF TLS IS ENABLED?
    SectionHeader {
        //% "Security"
        text: qsTrId("components_accounts-la-sip_security-header")
    }

    TextSwitch {
        id:ignoreTlsErrorsField

        property string _tpType: 'b'
        property string _tpParam: "param-ignore-tls-errors"
        property bool _tpDefault: false

        //: Switch to ignore TLS errors
        //% "Ignore TLS errors"
        text: qsTrId("components_accounts-la-sip_ignore_tls_errors")
    }

    TextSwitch {
        id: immutableStreamsField

        property string _tpType: 'b'
        property string _tpParam: "param-immutable-streams"
        property bool _tpDefault: false

        //% "Enable immutable streams"
        text: qsTrId("components_accounts-la-sip_immutable_streams")
    }

    TextSwitch {
        id: looseRoutingField

        property string _tpType: 'b'
        property string _tpParam: "param-loose-routing"
        property bool _tpDefault: false

        //: Switch to enable loose routing
        //% "Enable loose routing"
        text: qsTrId("components_accounts-la-sip_loose-routing")
    }

    TextSwitch {
        id: discoverBindingField

        property string _tpType: 'b'
        property string _tpParam: "param-discover-binding"
        property bool   _tpDefault: true

        checked: _tpDefault

        //: Switch to enable binding discovery
        //% "Enable binding discovery"
        text: qsTrId("components_accounts-la-sip_discover_binding")
    }

    TextSwitch {
        id: discoverStunField

        property string _tpType: 'b'
        property string _tpParam: "param-discover-stun"
        property bool   _tpDefault: true

        checked: _tpDefault

        //: Switch to enable STUN server discovery
        //% "Discover STUN"
        text: qsTrId("components_accounts-la-sip_discover_stun")
    }

    SectionHeader {
        visible: !discoverStunField.checked

        //% "STUN server settings"
        text: qsTrId("components_accounts-la-sip_stun_server-header")
    }

    TextField {
        id: stunServerField

        property string _tpType: 's'
        property string _tpParam: "param-stun-server"

        width: parent.width
        visible: !discoverStunField.checked

        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

        //% "STUN server"
        placeholderText: qsTrId("components_accounts-ph-sip_stun_server")

        //% "STUN server"
        label: qsTrId("components_accounts-la-sip_stun_server")
    }

    TextField {
        id: stunPortField

        property string _tpType: 's'
        property string _tpParam: "param-stun-port"

        width: parent.width
        visible: !discoverStunField.checked

        inputMethodHints: Qt.ImhDigitsOnly

        //% "Port"
        placeholderText: qsTrId("components_accounts-ph-sip_stun_port")

        //% "Port"
        label: qsTrId("components_accounts-la-sip_stun_port")
    }

    SectionHeader {
        //% "Keepalive"
        text: qsTrId("components_accounts-la-sip_keepalive-header")
    }

    ComboBox {
        id: keepaliveMechanismField

        property string _tpType: "e"
        property string _tpParam: "param-keepalive-mechanism"
        property string _tpDefault: "auto"

        width:parent.width

        //% "Keep-Alive mechanism"
        label: qsTrId("components_accounts-la-sip_keepalive_mechanism")

        menu: ContextMenu {
            MenuItem {
                property string _tpValue: "auto"

                //% "Automatic"
                text: qsTrId("components_accounts-la-sip_keepalive_mechanism_auto")
            }
            MenuItem {
                property string _tpValue: "register"

                //% "Register"
                text: qsTrId("components_accounts-la-sip_keepalive_mechanism_register")
            }
            MenuItem {
                property string _tpValue: "options"

                //% "Options"
                text: qsTrId("components_accounts-la-sip_keepalive_mechanism_options")
            }
            MenuItem {
                property string _tpValue: "stun"

                //% "STUN"
                text: qsTrId("components_accounts-la-sip_keepalive_mechanism_stun")
            }
            MenuItem {
                property string _tpValue: "off"

                //% "Disabled"
                text: qsTrId("components_accounts-la-sip_keepalive_mechanism_disabled")
            }
        }
    }

    TextField {
        id: keepaliveIntervalField

        property string _tpType: 's'
        property string _tpParam: "param-keepalive-interval"
        property string _tpDefault: '0'

        width: parent.width

        inputMethodHints: Qt.ImhDigitsOnly

        //% "0"
        placeholderText: qsTrId("components_accounts-ph-sip_keepalive_interval")

        //% "Keepalive interval"
        label: qsTrId("components_accounts-la-sip_keepalive_interval")

        text: _tpDefault
    }

    SectionHeader {
        //% "Local Address"
        text: qsTrId("components_accounts-la-sip_local_address-header")
    }

    TextField {
        id: localIpField

        property string _tpType: 's'
        property string _tpParam: "param-local-ip-address"

        width: parent.width

        inputMethodHints: Qt.ImhDigitsOnly

        //% "Local IP"
        placeholderText: qsTrId("components_accounts-ph-sip_local_ip")

        //% "Local IP"
        label: qsTrId("components_accounts-la-sip_local_ip")
    }

    TextField {
        id: localPortField

        property string _tpType: 's'
        property string _tpParam: "param-local-port"

        width: parent.width

        inputMethodHints: Qt.ImhDigitsOnly

        //% "Local port"
        placeholderText: qsTrId("components_accounts-ph-sip_local_port")

        //% "Local port"
        label: qsTrId("components_accounts-la-sip_local_port")
    }

    SectionHeader {
        //% "Extra Auth"
        text: qsTrId("components_accounts-la-sip_extra_auth-header")
    }

    TextField {
        id: extraAuthUserField

        property string _tpType: 's'
        property string _tpParam: "param-extra-auth-user"

        width: parent.width

        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

        //% "Extra auth user"
        placeholderText: qsTrId("components_accounts-ph-sip_extra_auth_user")

        //% "Extra auth user"
        label: qsTrId("components_accounts-la-sip_extra_auth_user")
    }

    TextField {
        id: extraAuthPasswordField

        property string _tpType: 's'
        property string _tpParam: "param-extra-auth-passowrd"

        width: parent.width

        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        echoMode: TextInput.Password

        //% "Extra auth password"
        placeholderText: qsTrId("components_accounts-ph-sip_extra_auth_password")

        //% "Extra auth password"
        label: qsTrId("components_accounts-la-sip_extra_auth_password")
    }
}
