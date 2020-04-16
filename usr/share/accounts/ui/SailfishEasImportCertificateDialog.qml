import QtQuick 2.6
import Sailfish.Silica 1.0
import com.jolla.sailfisheas 1.0

Dialog {
    id: root

    property CertificateHelper certificateHelper

    acceptDestinationAction: PageStackAction.Pop
    canAccept: !passphraseEntryBlock.visible

    DialogHeader {
        id: header
        //% "Enter password to import certificate"
        title: root.canAccept ? "" : qsTrId("components_accounts-hd-activesync_certificate_header")
        //: Header text
        //% "Import"
        acceptText: qsTrId("components_accounts-ph-activesync_certificate")
    }

    Column {
        id: passphraseEntryBlock

        anchors.top: header.bottom
        width: parent.width
        spacing: Theme.paddingMedium

        function extractCertificate() {
            certificateHelper.extractCertificate(passphraseInput.text)
        }

        PasswordField {
            id: passphraseInput

            focus: true
            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
            EnterKey.onClicked: passphraseEntryBlock.extractCertificate()
            //: Enter passphrase to extract certificate
            //% "Password"
            label: qsTrId("components_accounts-ph-activesync_certificate_placeholder_passphrase")

            //: Passphrase placeholder
            //% "Enter password"
            placeholderText: qsTrId("components_accounts-ph-activesync_certificate_label_passphrase")
            showEchoModeToggle: true

            onTextChanged: {
                passPhraseErrorLabel.text = ""
                extractButton.enabled = true
            }
        }

        Label {
            id: passPhraseErrorLabel
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            color: Theme.errorColor
            wrapMode: Text.Wrap
        }

        Button {
            id: extractButton

            anchors.horizontalCenter: parent.horizontalCenter
            //: Extract client's certificate from pkcs12 container.
            //% "Extract"
            text: qsTrId("components_accounts-bt-activesync_extract_certificate")
            onClicked: {
                if (!passphraseInput.text) {
                    //% "Password is required"
                    passPhraseErrorLabel.text = qsTrId("components_accounts-ph-activesync_certificate_passphrase_empty")
                } else {
                    enabled = false
                    passphraseEntryBlock.extractCertificate()
                }
            }
        }
    }

    Column {
        visible: !passphraseEntryBlock.visible
        anchors.top: header.bottom
        anchors.topMargin: Theme.itemSizeMedium
        width: parent.width
        spacing: Theme.paddingLarge

        Image {
            source: "image://theme/icon-l-acknowledge"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            horizontalAlignment: Text.AlignHCenter
            //% "Certificate is ready for import"
            text: qsTrId("components_accounts-lb-extraction_success_label")
            font.pixelSize: Theme.fontSizeExtraLarge
            color: Theme.highlightColor
            wrapMode: Text.Wrap
        }
    }

    Connections {
        target: certificateHelper
        onCertificateInfoChanged: {
            console.warn("[ssl-dbg] looks like cert extracted OK!")
            passphraseEntryBlock.visible = false
        }
        onCertificateExtractionFailed: {
            console.warn("[ssl-dbg] problem importing certificate")
            passphraseEntryBlock.visible = true
            //% "Certificate extraction has failed"
            passPhraseErrorLabel.text = qsTrId("components_accounts-la-wrong_passphrase")
        }
    }
}
