import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import com.jolla.sailfisheas 1.0

Column {
    id: root

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
    property bool limitedMode
    property bool checkMandatoryFields
    readonly property bool hasSslCertificate: sslConnectionCertificate.checked && sslCertificatePath.length > 0
    property alias sslCertificatePath: certificateHelper.certificatePath
    property alias sslCertificatePassword: certificateHelper.certificatePassphrase
    property alias sslCredentialsId: certificateHelper.credentialsId
    property bool oauthEnabled

    signal certificateDataSaved(int credentialsId)
    signal certificateDataSaveError(string errorMessage)

    function storeCertificateData() {
        console.log("storing certificate data")
        certificateHelper.storeData()
    }

    function loadCertificateData(credentialsId, sslCertificatePath) {
        console.log("loading ssl cert config", credentialsId, sslCertificatePath)
        certificateHelper.loadData(credentialsId, sslCertificatePath)
    }

    width: parent.width

    TextField {
        id: emailaddressField
        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhEmailCharactersOnly
        //% "Email address"
        label: qsTrId("components_accounts-la-activesync_emailaddress")
        errorHighlight: !text && checkMandatoryFields

        //% "Email address is required"
        description: errorHighlight ? qsTrId("components_accounts-la-activesync_emailaddress_required") : ""

        EnterKey.iconSource: usernameField.visible || passwordField.visible || domainField.visible || editMode
            ? "image://theme/icon-m-enter-next"
            : "image://theme/icon-m-enter-close"
        EnterKey.onClicked: {
            if (usernameField.visible) {
                usernameField.focus = true
            } else if (passwordField.visible) {
                passwordField.focus = true
            } else if (domainField.visible) {
                domainField.focus = true
            } else if (editMode) {
                serverField.focus = true
            } else {
                emailaddressField.focus = false
            }
        }
    }

    TextField {
        id: usernameField
        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        //: Account username
        //% "Username"
        label: qsTrId("components_accounts-la-activesync_username")
        errorHighlight: !text && checkMandatoryFields

        //% "Username is required"
        description: errorHighlight ? qsTrId("components_accounts-la-activesync_username_required") : ""

        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: passwordField.focus = true
        visible: !limitedMode && !oauthEnabled
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

        //% "Password is required"
        description: errorHighlight ? qsTrId("components_accounts-la-activesync_password_required") : ""

        visible: !oauthEnabled

        EnterKey.iconSource: domainField.visible ? "image://theme/icon-m-enter-next"
                                                 : "image://theme/icon-m-enter-close"
        EnterKey.onClicked: {
            if (domainField.visible) {
                domainField.focus = true
            } else {
                passwordField.focus = false
            }
        }
    }

    SectionHeader {
        //% "Server"
        text: qsTrId("components_accounts-he-server")
        visible: !limitedMode
    }

    TextField {
        id: domainField

        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        //% "Domain"
        label: qsTrId("components_accounts-la-activesync_domain")
        EnterKey.iconSource: editMode ? "image://theme/icon-m-enter-next"
                                      : "image://theme/icon-m-enter-close"
        EnterKey.onClicked: {
            if (editMode) {
                serverField.focus = true
            } else {
                domainField.focus = false
            }
        }
        visible: !limitedMode && !oauthEnabled
    }

    Column {
        clip: true
        enabled: editMode
        height: enabled ? implicitHeight : 0
        opacity: enabled ? 1.0 : 0.0
        width: parent.width
        visible: !limitedMode
        Behavior on height { NumberAnimation { easing.type: Easing.InOutQuad; duration: 400 } }
        Behavior on opacity { FadeAnimation { duration: 400 } }

        TextField {
            id: serverField

            //% "Address"
            label: qsTrId("components_accounts-la-activesync_server_address")
            errorHighlight: !text && checkMandatoryFields
            inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

            //% "Server address is required"
            description: errorHighlight ? qsTrId("components_accounts-la-activesync_server_address_required") : ""

            EnterKey.iconSource: "image://theme/icon-m-enter-next"
            EnterKey.onClicked: portField.focus = true
        }

        TextField {
            id: portField

            //: Server port
            //% "Port"
            label: qsTrId("components_accounts-la-activesync_server_port")

            inputMethodHints: Qt.ImhDigitsOnly
            validator: IntValidator { bottom: 1; top: 65535 }

            //% "Port number must be a value between 1 and 65535"
            description: errorHighlight ? qsTrId("settings_network_la-proxy_port_number_error") : ""

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
            //% "Secure connection (SSL)"
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

        TextSwitch {
            id: sslConnectionCertificate
            checked: sslCertificatePath.length > 0
            automaticCheck: false
            onClicked: {
                if (!checked || certificateHelper.certificatePath == "") {
                    checked = !checked
                } else {
                    var сertificateWarning = pageStack.push(Qt.resolvedUrl("SailfishEasSSLCertificateWarningDialog.qml"))
                    сertificateWarning.accepted.connect(function() {
                        certificateHelper.cleanupData()
                        sslConnectionCertificate.checked = false
                    })
                }
            }

            //: Connection with account ssl certificate
            //% "Use client SSL certificate"
            text: qsTrId("components_accounts-la-activesync_secure_ssl_connection")
        }

        BackgroundItem {
            id: addCert

            width: parent.width
            height: addCertRow.height
            enabled: sslConnectionCertificate.checked && !sslCertificatePath

            onClicked: {
                pageStack.animatorPush(filePickerPage)
            }

            Row {
                id: addCertRow

                x: Theme.itemSizeExtraSmall
                width: parent.width - Theme.itemSizeExtraSmall
                anchors.verticalCenter: parent.verticalCenter

                Label {
                    width: parent.width - addCertIcon.width - Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                    color: {
                        if (addCert.highlighted || (sslCertificatePath.length > 0)) {
                            return Theme.highlightColor
                        } else if (sslConnectionCertificate.checked) {
                            return Theme.primaryColor
                        } else {
                            return Theme.secondaryColor
                        }
                    }
                    truncationMode: TruncationMode.Fade
                    text: sslCertificatePath.length > 0 ? certificateHelper.certificateIssuer
                                                        : //% "Add certificate"
                                                          qsTrId("components_accounts-la-ssl_certificate_add")
                }

                IconButton {
                    id: addCertIcon

                    anchors.verticalCenter: parent.verticalCenter
                    icon.source: sslCertificatePath.length > 0 ? "image://theme/icon-m-clear"
                                                               : "image://theme/icon-m-add"
                    highlighted: addCert.pressed
                    enabled: sslConnectionCertificate.checked
                    onClicked: {
                        if (!sslCertificatePath) {
                            pageStack.animatorPush(filePickerPage)
                        } else {
                            var сertificateWarning = pageStack.push(Qt.resolvedUrl("SailfishEasSSLCertificateWarningDialog.qml"))
                            сertificateWarning.accepted.connect(function() {
                                certificateHelper.cleanupData()
                            })
                        }
                    }
                }
            }
        }

        Component {
            id: filePickerPage
            FilePickerPage {
                id: certPicker
                nameFilters: [ '*.cer', '*.pem', '*.pfx', '*.p12' ]
                onSelectedContentPropertiesChanged: {
                    var _lastAppPage = pageStack.previousPage(certPicker)
                    certificateHelper.setCertificatePath(selectedContentProperties.filePath)
                    pageStack.animatorReplaceAbove(_lastAppPage,
                                                   certificateImport,
                                                   {certificateHelper: certificateHelper})
                }
            }
        }

        Component {
            id: certificateImport
            SailfishEasImportCertificateDialog {
                onRejected: {
                    certificateHelper.cleanupData()
                }
            }
        }

        CertificateHelper {
            id: certificateHelper
            onStoreDataSucceeded: {
                console.log("certificate data saved")
                root.certificateDataSaved(id)
            }
            onStoreDataFailed: {
                console.log("certificate data save error")
                root.certificateDataSaveError(errorMessage)
            }
        }
    }
}
