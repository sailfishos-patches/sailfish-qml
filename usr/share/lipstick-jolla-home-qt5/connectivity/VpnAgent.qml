import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import com.jolla.lipstick 0.1
import org.nemomobile.lipstick 0.1
import "../systemwindow"
import "../main"

SystemWindow {
    id: vpnDialog

    /* Note:it is difficult to know what content will be provided by connman when this dialog is invoked.
     * The input may be tested by variations of the following python script:

    import dbus

    lipstick = dbus.SystemBus().get_object("org.nemomobile.lipstick", "/org/nemomobile/lipstick/vpnagent")
    agent = dbus.Interface(lipstick, dbus_interface='net.connman.vpn.Agent')
    requestInput = agent.get_dbus_method("RequestInput")

    d = dbus.Dictionary({
            "Name": dbus.Dictionary({
                "Type": dbus.String("string"),
                "Requirement": dbus.String("informational"),
                "Value": dbus.String("SecureConn")
            }, signature='sv'),
            "OpenVPN.Username": dbus.Dictionary({
                "Type": dbus.String("string"),
                "Requirement": dbus.String("mandatory"),
                "Value": dbus.String("alice")
            }, signature='sv'),
            "OpenVPN.Password": dbus.Dictionary({
                "Type": dbus.String("password"),
                "Requirement": dbus.String("mandatory")
            }, signature='sv'),
            "Domain": dbus.Dictionary({
                "Type": dbus.String("string"),
                "Requirement": dbus.String("optional")
            }, signature='sv')
        }, signature='sv')

    print requestInput(dbus.ObjectPath("/no_such_connection"), d)
    */

    property alias __silica_applicationwindow_instance: fakeApplicationWindow
    property bool verticalOrientation: Lipstick.compositor.topmostWindowOrientation === Qt.PrimaryOrientation
                                    || Lipstick.compositor.topmostWindowOrientation === Qt.PortraitOrientation
                                    || Lipstick.compositor.topmostWindowOrientation === Qt.InvertedPortraitOrientation
    property real keyboardHeight: transpose ? Qt.inputMethod.keyboardRectangle.width : Qt.inputMethod.keyboardRectangle.height
    property real reservedHeight: Math.max(((Screen.sizeCategory < Screen.Large) ? 0.2 * height
                                                                                 : 0.4 * height),
                                           keyboardHeight) - 1

    property var requestPath
    property var requestDetails: ({})
    property var fields: []
    property string vpnName
    property var responseProvided
    property bool allMandatory

    objectName: "vpnDialog"
    _windowOpacity: shouldBeVisible ? 1.0 : 0.0
    contentHeight: content.height

    onHidden: {
        var responsePath = requestPath
        vpnAgent.windowVisible = false
        requestPath = ''

        if (responsePath) {
            if (responseProvided) {
                vpnAgent.respond(responsePath, requestDetails)
            } else {
                vpnAgent.decline(responsePath)
            }
        }
    }

    // animate height with keyboard, but not on orientation changes
    Behavior on keyboardHeight { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

    Item {
        id: fakeApplicationWindow
        // suppresses warnings by context menu
        function _undim() {}
        function _dimScreen() {}
    }

    function presentationName(received) {
        if (received === 'Host') {
            //% "Host"
            return qsTrId("lipstick-jolla-home-la-vpnagent_host")
        } else if (received === 'OpenVPN.Username' || received === 'Username') {
            //% "User name"
            return qsTrId("lipstick-jolla-home-la-vpnagent_openvpn_username")
        } else if (received === 'OpenVPN.Password' || received === 'Password' || received === 'OpenVPN.PrivateKeyPassword' || received === 'OpenConnect.PKCSPassword') {
            //% "Password"
            return qsTrId("lipstick-jolla-home-la-vpnagent_openvpn_password")
        } else if (received === 'OpenConnect.CACert') {
            //% "Additional CA keys file"
            return qsTrId("lipstick-jolla-home-la-vpnagent_openconnect_cacert")
        } else if (received === 'OpenConnect.ClientCert') {
            //% "Client certificate file"
            return qsTrId("lipstick-jolla-home-la-vpnagent_openconnect_clientcert")
        } else if (received === 'OpenConnect.ServerCert') {
            //% "Server certificate hash"
            return qsTrId("lipstick-jolla-home-la-vpnagent_openconnect_servercert")
        } else if (received === 'OpenConnect.VPNHost') {
            //% "Server after authentication"
            return qsTrId("lipstick-jolla-home-la-vpnagent_openconnect_vpnhost")
        } else if (received === 'OpenConnect.Cookie') {
            //% "WebVPN cookie data"
            return qsTrId("lipstick-jolla-home-la-vpnagent_openconnect_cookie")
        } else if (received === 'OpenConnect.PKCSClientCert') {
            //% "PKCS#1/#8/#12 certificate file"
            return qsTrId("lipstick-jolla-home-la-vpnagent_openconnect_pkcscert")
        } else if (received === 'VPNC.IPSec.Secret') {
            //% "IPSec secret"
            return qsTrId("lipstick-jolla-home-la-vpnagent_vpnc_secret")
        } else if (received === 'VPNC.Xauth.Username') {
            //% "Username"
            return qsTrId("lipstick-jolla-home-la-vpnagent_vpnc_username")
        } else if (received === 'VPNC.Xauth.Password') {
            //% "Password"
            return qsTrId("lipstick-jolla-home-la-vpnagent_vpnc_password")
        } else if (received === 'Enter Private Key password') {
            //% "Enter Private Key password"
            return qsTrId("lipstick-jolla-home-la-vpnagent_enter_private_key_password")
        } else if (received === 'VpnAgent.AuthFailure') {
            //% "Authentication failed"
            return qsTrId("lipstick-jolla-home-la-vpnagent_authentication_failed")
        }
        return received
    }

    function prepare(path, details) {
        var displayOverride = {}
        requestPath = path
        requestDetails = details

        var informational = []
        var priority = []
        var mandatory = []
        var optional = []

        fieldRepeater.model = []

        storeCredentials.visible = false
        storeCredentials.checked = false
        allMandatory = true
        for (var name in requestDetails) {
            var itemDetails = requestDetails[name]
            var requirement = itemDetails['Requirement']
            var type = itemDetails['Type']
            var value = itemDetails['Value']
            if ((name === 'Name') && (type === 'string')) {
                // Ensure the Name property is shown first, if present
                vpnName = value
            } else if (requirement === 'control') {
                switch (name) {
                case 'storeCredentials':
                    if (type === 'boolean') {
                        storeCredentials.visible = true
                        storeCredentials.checked = value
                    } else {
                        console.log("storeCredentials parameter must be a boolean")
                    }
                    break
                case 'Title':
                    if (type === 'string') {
                        header.title = value
                    } else {
                        console.log("Title parameter must be a string")
                    }
                    break
                case 'Description':
                    if (type === 'string') {
                        var descriptionDetails = {
                            'name': name,
                            'displayName': "",
                            'type': "string",
                            'value': value,
                            'requirement': 'informational'
                        }
                        informational.unshift(descriptionDetails)
                    } else {
                        console.log("Description parameter must be a string")
                    }
                    break
                default:
                    if ((type === 'string') && (name.substr(-12) === ".displayName")) {
                        displayOverride[name.slice(0, -12)] = value
                    } else {
                        console.log("Ignoring non-standard control parameter: " + name)
                    }
                    break
                }
            } else {
                var displayDetails = {
                    'name': name,
                    'displayName': name,
                    'type': type,
                    'value': value,
                    'requirement': requirement
                }

                // 'alternate' not currently supported - the documentation is quite vague:
                // http://git.kernel.org/cgit/network/connman/connman.git/tree/doc/vpn-agent-api.txt
                var destination = null
                switch (requirement) {
                case 'informational':
                    if (type === 'string') {
                        destination = informational
                    } else {
                        console.log("Informational parameter must be a string")
                    }
                    break
                case 'mandatory':
                    destination = mandatory
                    break
                case 'optional':
                    destination = optional
                    allMandatory = false
                    break
                default:
                    console.log("Requirement parameter not supported: " + requirement)
                    break;
                }

                if (destination) {
                    if (name === 'OpenVPN.Username'
                            || name === 'Username'
                            || name === 'OpenConnect.Cookie'
                            || name === 'VPNC.IPSec.Secret') {
                        destination = priority
                    }
                    destination.push(displayDetails)
                }
            }
        }

        var fields = informational.concat(priority, mandatory, optional)

        for (var i in fields) {
            if (displayOverride.hasOwnProperty(fields[i].name)) {
                fields[i].displayName = displayOverride[fields[i].name]
            }
        }

        fieldRepeater.model = fields
        updateAllNonEmpty()
    }

    function closeDialog(responseProvided) {
        vpnDialog.responseProvided = responseProvided
        shouldBeVisible = false
    }

    function focusNextTextField(modelIndex) {
        for (var i = modelIndex + 1; i < fieldRepeater.count; ++i) {
            var item = fieldRepeater.itemAt(i)
            if (item.item.hasOwnProperty('cursorPosition')) {
                item.focus = true
                return
            }
        }

        fieldRepeater.itemAt(modelIndex).item.focus = false
    }

    function updateAllNonEmpty() {
        var allNonEmpty = true
        for (var i = 0; i < fieldRepeater.count; ++i) {
            var item = fieldRepeater.itemAt(i)
            if (item) {
                item = item.item
                if (item && item.hasOwnProperty('nonEmpty') && item.hasOwnProperty('mandatory')) {
                    if (item.mandatory && !item.nonEmpty) {
                        allNonEmpty = false
                        break
                    }
                }
            }
        }

        fieldRepeater.allNonEmpty = allNonEmpty
    }

    SystemDialogLayout {
        id: dialogLayout

        contentHeight: content.height

        onDismiss: vpnDialog.closeDialog(false)
    }

    SilicaFlickable {
        id: content

        property real maxHeight: (verticalOrientation ? Screen.height : Screen.width) - reservedHeight

        width: parent.width
        height: Math.min(contentHeight, maxHeight)
        contentHeight: column.height
        clip: contentHeight > maxHeight

        Column {
            id: column

            width: parent.width

            SystemDialogHeader {
                id: header
                /// VPN connect prompt; %1 is the VPN name
                //% "Connect to %1"
                title: qsTrId("lipstick-jolla-home-he-enter_vpn_credentials").arg(vpnName)
                topPadding: Screen.sizeCategory >= Screen.Large ? 2*Theme.paddingLarge : Theme.paddingLarge
            }

            Column {
                width: parent.width

                Repeater {
                    id: fieldRepeater
                    property bool allNonEmpty

                    delegate: Loader {
                        property string name: modelData.name
                        property string displayName: modelData.displayName
                        property var value: modelData.value
                        property string requirement: modelData.requirement
                        property int modelIndex: index
                        property bool mandatory: modelData.requirement === "mandatory"

                        width: parent.width
                        sourceComponent: modelData.requirement === "informational" ? informationItem
                                       : modelData.type === 'boolean' ? booleanEditor
                                       : modelData.type === 'password' ? passwordEditor
                                       : textEditor
                    }
                }
            }

            TextSwitch {
                id: storeCredentials

                //% "Remember credential information"
                text: qsTrId("lipstick-jolla-home-he-vpn_store_credentials")

                onCheckedChanged: vpnDialog.requestDetails['storeCredentials'].Value = checked
            }

            Item {
                id: buttonContainer
                width: parent.width
                height: connectButton.height

                SystemDialogTextButton {
                    anchors {
                        left: buttonContainer.left
                        right: buttonContainer.horizontalCenter
                        top: buttonContainer.top
                    }

                    //: Cancel connection attempt
                    //% "Cancel"
                    text: qsTrId("lipstick-jolla-home-la-vpn_connect_cancel")
                    onClicked: vpnDialog.closeDialog(false)
                }

                SystemDialogTextButton {
                    id: connectButton

                    anchors {
                        left: buttonContainer.horizontalCenter
                        right: buttonContainer.right
                        top: buttonContainer.top
                    }

                    //: Connect VPN
                    //% "Connect"
                    text: qsTrId("lipstick-jolla-home-la-vpn_connect")
                    enabled: fieldRepeater.allNonEmpty
                    onClicked: vpnDialog.closeDialog(true)
                }
            }
        }

        VerticalScrollDecorator {}
    }

    Component {
        id: booleanEditor

        TextSwitch {
            id: booleanSelection

            text: vpnDialog.presentationName(displayName)
            checked: value
            onCheckedChanged: vpnDialog.requestDetails[name].Value = checked
        }
    }

    Component {
        id: passwordEditor

        PasswordField {
            id: textPasswordField

            property bool nonEmpty: text !== ''
            property bool mandatory: requirement === "mandatory"

            onNonEmptyChanged: vpnDialog.updateAllNonEmpty()
            width: parent.width
            inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
            label: vpnDialog.presentationName(displayName)
            placeholderText: label
            text: value
            onTextChanged: {
                vpnDialog.requestDetails[name].Value = text
                if (mandatory && text !== '') {
                    errorHighlight = false
                }
            }
            onActiveFocusChanged: {
                if (!activeFocus && mandatory && text === '') {
                    errorHighlight = true
                }
            }
            EnterKey.iconSource: "image://theme/icon-m-enter-" + (modelIndex == (fieldRepeater.count - 1) ? "close" : "next")
            EnterKey.onClicked: vpnDialog.focusNextTextField(modelIndex)
            focus: true // inside Loader scope
            _placeholderTextLabel.anchors.rightMargin: textRightMargin + (mandatory ? textPasswordAsterisk.width : 0)

            Image {
                id: textPasswordAsterisk
                parent: textPasswordField
                x: Math.min(_placeholderTextLabel.contentWidth + parent.textLeftMargin, parent.width - parent.textRightMargin - width)
                width: Theme.iconSizeSmall
                height: Theme.iconSizeSmall
                anchors {
                    top: parent.top
                    topMargin: parent.textTopMargin
                }
                visible: !allMandatory && mandatory
                opacity: _placeholderTextLabel.opacity

                source: "image://theme/icon-m-asterisk?" + parent.color
            }
        }
    }

    Component {
        id: textEditor

        TextField {
            id: textEditorField

            property bool nonEmpty: text !== ''
            property bool mandatory: requirement === "mandatory"

            onNonEmptyChanged: vpnDialog.updateAllNonEmpty()
            width: parent.width
            inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
            label: vpnDialog.presentationName(displayName)
            text: value
            placeholderText: label
            onTextChanged: {
                vpnDialog.requestDetails[name].Value = text
                if (mandatory && text !== '') {
                    errorHighlight = false
                }
            }
            onActiveFocusChanged: {
                if (!activeFocus && mandatory && text === '') {
                    errorHighlight = true
                }
            }
            EnterKey.iconSource: "image://theme/icon-m-enter-" + (modelIndex == (fieldRepeater.count - 1) ? "close" : "next")
            EnterKey.onClicked: vpnDialog.focusNextTextField(modelIndex)
            focus: true // inside Loader scope
            _placeholderTextLabel.anchors.rightMargin: textRightMargin + (mandatory ? textEditorAsterisk.width : 0)

            Image {
                id: textEditorAsterisk
                parent: textEditorField
                x: Math.min(_placeholderTextLabel.contentWidth + parent.textLeftMargin, parent.width - Theme.horizontalPageMargin - width)
                width: Theme.iconSizeSmall
                height: Theme.iconSizeSmall
                anchors {
                    top: parent.top
                    topMargin: parent.textTopMargin
                }
                visible:  !allMandatory && mandatory
                opacity: _placeholderTextLabel.opacity

                source: "image://theme/icon-m-asterisk?" + parent.color
            }
        }
    }

    Component {
        id: informationItem

        Flow {
            id: flow
            property bool mandatory

            x: Theme.horizontalPageMargin
            width: parent.width - x*2
            y: Theme.paddingSmall
            bottomPadding: 2 * Theme.paddingMedium

            Label {
                width: text === "" ? 0 : implicitWidth + Theme.paddingMedium
                text: presentationName(displayName)
                color: Theme.highlightColor
            }
            Label {
                text: value
                wrapMode: Text.Wrap
                color: Theme.secondaryHighlightColor
            }
        }
    }

    Connections {
        target: vpnAgent
        onWindowVisibleChanged: {
            if (vpnAgent.windowVisible) {
                vpnDialog.shouldBeVisible = true
            }
        }
        onInputRequested: {
            vpnDialog.prepare(path, details)
            vpnAgent.windowVisible = true
        }
        onRequestCanceled: {
            console.log('requestCanceled - path:', path)
        }
        onErrorReported: {
            console.log('errorReported - path:', path, 'message:', message)
        }
    }
}
