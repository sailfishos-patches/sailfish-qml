import QtQuick 2.0
import MeeGo.QOfono 0.2
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import Sailfish.Settings.Networking 1.0
import com.jolla.settings.system 1.0

Page {
    id: editMobileNetworkPage

    property alias mobileContextPath: context1.contextPath
    property alias title: pageHeader.title

    property bool _mmsMode: (context1.type === "mms")
    property bool _contextChanged
    property bool _applyChanges
    property bool _provisionContext
    readonly property bool _initialized: context1.valid && !_provisionContext && !context1.provisioning && !provisionDelay.running
    readonly property bool _hasAuthentication: authenticationSelection.currentIndex > 0

    readonly property variant _protocolValues: ["ip", "ipv6", "dual"]
    readonly property variant _authenticationValues: ["none", "pap", "chap", "any"]

    on_InitializedChanged: {
        if (_initialized) {
            updateUI()
            _contextChanged = false
        }
    }

    OfonoContextConnection {
        id: context1
        onActiveChanged: {
            if (!active) {
                if (_applyChanges) {
                    updateContext()
                    _applyChanges = false
                    _contextChanged = false
                }
                if (_provisionContext) {
                    _provisionContext = false
                    context1.provision()
                }
            }
        }
        onValidChanged: if (!valid && status === PageStatus.Active) pageStack.pop()
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            if (!context1.valid) pageStack.pop()
        } else if (status === PageStatus.Activating) {
            if (_initialized) {
                updateUI()
                _contextChanged = false
            }
        } else if (status === PageStatus.Deactivating) {
            // Make sure that keyboard goes away
            takeFocusOffEditFields()
            if (_contextChanged) {
                if (context1.active) {
                    // Can't apply changes to the active context
                    _applyChanges = true
                    context1.active = false
                } else {
                    // Update would still fail if context is being activated
                    // but there's nothing we can do about it. That's the way
                    // ofono is designed.
                    updateContext()
                    _contextChanged = false
                }
            }
        }
    }

    function takeFocusOffEditFields() {
        connectionNameInput.focus = false
        apnInput.focus = false
        usernameInput.focus = false
        passwordInput.focus = false
        proxyAddress.focus = false
        proxyPort.focus = false
        mmscAddress.focus = false
    }

    function updateContext() {
        context1.accessPointName = apnInput.text
        context1.name = connectionNameInput.text
        if (protocolSelection.currentIndex >= 0) {
            context1.protocol = _protocolValues[protocolSelection.currentIndex]
        }
        if (authenticationSelection.currentIndex >= 0) {
            context1.authMethod = _authenticationValues[authenticationSelection.currentIndex]
        }

        if (_hasAuthentication) {
            context1.username = usernameInput.text
            context1.password = passwordInput.text
        } else {
            context1.username = ""
            context1.password = ""
        }

        if (_mmsMode) {
            var address = proxyAddress.text.trim()
            if (address === "") {
                context1.messageProxy = ""
            } else {
                var port = proxyPort.text.trim()
                if (port === "") {
                    context1.messageProxy = address
                } else {
                    context1.messageProxy = address + ":" + port
                }
            }
            context1.messageCenter = mmscAddress.text
        }
    }

    function updateUI() {
        apnInput.text = context1.accessPointName
        usernameInput.text = context1.username
        passwordInput.text = context1.password
        connectionNameInput.text = context1.name

        var protocol = context1.protocol
        var index = _protocolValues.indexOf(protocol)
        if (index >= 0) {
            protocolSelection.currentIndex = index
        } else {
            console.log("Unsupported protocol", protocol)
            protocolSelection.currentIndex = -1
        }

        var authentication = context1.authMethod

        index = _authenticationValues.indexOf(authentication)
        if (index >= 0) {
            authenticationSelection.currentIndex = index
        } else {
            console.log("Unsupported authentication", authentication)
            authenticationSelection.currentIndex = -1
        }

        var colon = context1.messageProxy.lastIndexOf(":")
        if (colon >= 0) {
            proxyAddress.text = context1.messageProxy.slice(0, colon)
            proxyPort.text = context1.messageProxy.slice(colon+1, context1.messageProxy.length)
        } else {
            proxyAddress.text = context1.messageProxy
        }
        mmscAddress.text = context1.messageCenter
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + pageHeader.height + Theme.paddingLarge

        VerticalScrollDecorator { }

        PullDownMenu {
            visible: !disabledByMdmBanner.active
            MenuItem {
                //% "Reset to default"
                text: qsTrId("settings_network-me-reset_connection_context")
                enabled: _initialized
                onClicked: {
                    if (context1.active) {
                        // Can't provision active context
                        _provisionContext = true
                        context1.active = false
                    } else {
                        // Provisioning would still fail if context is being
                        // activated for the same reason why property update
                        // would fail. The process of updating ofono context
                        // properties is unreliable by design.
                        context1.provision()
                    }
                    provisionDelay.restart()
                    takeFocusOffEditFields()
                }
            }
        }

        PageHeader {
            id: pageHeader
        }

        Column {
            id: content
            width: parent.width
            anchors.top: pageHeader.bottom
            visible: opacity > 0
            opacity: _initialized ? 1.0 : 0.0
            enabled: !disabledByMdmBanner.active

            Behavior on opacity { FadeAnimation { } }

            DisabledByMdmBanner {
                id: disabledByMdmBanner
                active: !AccessPolicy.mobileDataAccessPointSettingsEnabled
            }

            TextField {
                id: connectionNameInput
                width: parent.width
                inputMethodHints: Qt.ImhNoPredictiveText
                //% "Connection name"
                label: qsTrId("settings_network-la-connection_name")
                //% "Enter connection name"
                placeholderText: qsTrId("settings_network-ph-enter_connection_name")
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: apnInput.focus = true
                onTextChanged: if (_initialized) _contextChanged = true
            }

            TextField {
                id: apnInput
                width: parent.width
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                //% "Access point name"
                label: qsTrId("settings_network-la-access_point_name")
                //% "Enter access point name"
                placeholderText: qsTrId("settings_network-ph-enter_access_point_name")
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: usernameInput.focus = true
                onTextChanged: if (_initialized) _contextChanged = true
            }

            ComboBox {
                id: protocolSelection
                enabled: !disabledByMdmBanner.active
                //: Cellular data protocol selection label
                //% "Protocol"
                label: qsTrId("settings_network-bt-protocol")
                width: parent.width
                onCurrentIndexChanged: if (_initialized) _contextChanged = true
                menu: ContextMenu {
                    //: Cellular data protocol selection item
                    //% "IP"
                    MenuItem { text: qsTrId("settings_network-me-protocol_ip") }
                    //: Cellular data protocol selection item
                    //% "IPv6"
                    MenuItem { text: qsTrId("settings_network-me-protocol_ipv6") }
                    //: Cellular data protocol selection item
                    //% "Dual"
                    MenuItem { text: qsTrId("settings_network-me-protocol_dual") }
                }
            }

            SectionHeader {
                //: Section header in mobile network page
                //% "Security"
                text: qsTrId("settings_network-he-security")
            }

            ComboBox {
                id: authenticationSelection
                enabled: !disabledByMdmBanner.active
                //% "Authentication"
                label: qsTrId("settings_network-bt-authentication")
                width: parent.width
                onCurrentIndexChanged: if (_initialized) _contextChanged = true
                menu: ContextMenu {
                    //% "None"
                    MenuItem { text: qsTrId("settings_network-me-none") }
                    //% "PAP"
                    MenuItem { text: qsTrId("settings_network-me-authentication_pap") }
                    //% "CHAP"
                    MenuItem { text: qsTrId("settings_network-me-authentication_chap") }
                    //% "PAP or CHAP"
                    MenuItem { text: qsTrId("settings_network-me-authentication_pap_or_chap") }
                }
            }

            Column {
                clip: true
                width: parent.width
                enabled: _hasAuthentication
                height: enabled ? implicitHeight : 0
                opacity: enabled ? 1.0 : 0.0
                Behavior on opacity { FadeAnimation {} }
                TextField {
                    id: usernameInput
                    width: parent.width
                    inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                    //% "Username"
                    label: qsTrId("settings_network-la-username")
                    //% "Enter username"
                    placeholderText: qsTrId("settings_network-ph-enter_username")
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: passwordInput.focus = true
                    onTextChanged: if (_initialized) _contextChanged = true
                }

                SystemPasswordField {
                    id: passwordInput
                    //% "Enter Password"
                    placeholderText: qsTrId("settings_network-la-enter_password")
                    EnterKey.iconSource: _mmsMode ? "image://theme/icon-m-enter-next" : "image://theme/icon-m-enter-close"
                    EnterKey.onClicked: {
                        if (_mmsMode) {
                            proxyAddress.focus = true
                        } else {
                            parent.focus = true
                        }
                    }
                    onTextChanged: if (_initialized) _contextChanged = true
                }
            }

            Column {
                id: mmsOptionsColumn
                width: parent.width
                visible: _mmsMode

                SectionHeader {
                    //: Proxy section header in mobile network page
                    //% "Proxy"
                    text: qsTrId("settings_network-he-proxy")
                }

                TextField {
                    id: proxyAddress
                    width: parent.width
                    inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                    //% "Proxy address"
                    label: qsTrId("settings_network-la-proxy_address")
                    //% "Enter proxy address"
                    placeholderText: qsTrId("settings_network-ph-enter_proxy_address")
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: proxyPort.focus = true
                    onTextChanged: if (_initialized) _contextChanged = true
                }

                TextField {
                    id: proxyPort
                    width: parent.width
                    inputMethodHints: Qt.ImhDigitsOnly
                    //% "Proxy port"
                    label: qsTrId("settings_network-la-proxy_port")
                    //% "Enter proxy port"
                    placeholderText: qsTrId("settings_network-la-enter_proxy_port")
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: mmscAddress.focus = true
                    onTextChanged: if (_initialized) _contextChanged = true
                }

                SectionHeader {
                    //: MMSC section header in mobile network page
                    //% "MMSC"
                    text: qsTrId("settings_network-he-mmsc")
                }

                TextField {
                    id: mmscAddress
                    width: parent.width
                    inputMethodHints: Qt.ImhUrlCharactersOnly
                    //% "MMSC address"
                    label: qsTrId("settings_network-la-mmsc_address")
                    //% "Enter MMSC address"
                    placeholderText: qsTrId("settings_network-ph-enter_mmsc_address")
                    EnterKey.iconSource: "image://theme/icon-m-enter-close"
                    EnterKey.onClicked: parent.focus = true
                    onTextChanged: if (_initialized) _contextChanged = true
                }
            }
        }//Column
    } //Flickable

    PageBusyIndicator {
        running: !_initialized
    }

    Timer {
        id: provisionDelay
        repeat: false
        interval: 1000
    }
}
