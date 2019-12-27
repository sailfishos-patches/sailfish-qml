import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.voicecall.settings.translations 1.0
import org.nemomobile.notifications 1.0
import Nemo.Configuration 1.0
import MeeGo.QOfono 0.2

Column {
    id: root
    property string modemPath
    property string voiceMailboxNumber: mailboxNumber()
    onVoiceMailboxNumberChanged: mailboxEditor.text = voiceMailboxNumber

    function applySettings() {
        if (mailboxEditor.text != voiceMailboxNumber) {
            mailboxConfig.value = mailboxEditor.text
        }
        // TODO: Try storing to SIM once oFono supports it JB#10808
    }

    function mailboxNumber() {
        if (!ofonoSimManager.present) {
            return ""
        }
        var mailbox = mailboxConfig.value
        if (ofonoMessageWaiting.ready && mailbox == "") {
            mailbox = ofonoMessageWaiting.voicemailMailboxNumber
        }
        return mailbox
    }

    SectionHeader {
        //% "Voicemail"
        text: qsTrId("settings_phone-he-voicemail")
    }

    Label {
        anchors {
            left: parent.left
            right: parent.right
            margins: Theme.paddingLarge
        }
        wrapMode: Text.Wrap
        visible: !ofonoMessageWaiting.ready || !ofonoSimManager.present
        color: Theme.secondaryColor
        font.pixelSize: Theme.fontSizeSmall
        //% "Voicemail settings are unavailable"
        text: qsTrId("settings_phone-he-voicemail_setting_not_available")
    }

    Item {
        width: parent.width
        height: mailboxEditor.height
        visible: ofonoMessageWaiting.ready && ofonoSimManager.present
        TextField {
            id: mailboxEditor
            anchors {
                left: parent.left
                right: resetButton.left
            }

            text: voiceMailboxNumber
            inputMethodHints: Qt.ImhDialableCharactersOnly
            //% "Enter voicemail number"
            placeholderText: qsTrId("settings_phone-la-enter_voicemail_number")
            //% "Voicemail number"
            label: qsTrId("settings_phone-la-voicemail_number")
            EnterKey.iconSource: "image://theme/icon-m-enter-close"
            EnterKey.onClicked: focus = false
            onActiveFocusChanged: applySettings()
            textRightMargin: Theme.paddingMedium
        }
        IconButton {
            id: resetButton
            anchors {
                top: parent.top
                topMargin: -Theme.paddingSmall
                right: parent.right
                rightMargin: Theme.horizontalPageMargin - Theme.paddingMedium
            }
            enabled: mailboxEditor.text != ofonoMessageWaiting.voicemailMailboxNumber
            icon.source: "image://theme/icon-m-clear"
            onClicked: {
                mailboxConfig.value = ""
                mailboxEditor.text = voiceMailboxNumber
            }
        }
    }

    OfonoMessageWaiting {
        id: ofonoMessageWaiting
        modemPath: root.modemPath
    }

    OfonoSimManager {
        id: ofonoSimManager
        modemPath: root.modemPath
    }

    ConfigurationValue {
        id: mailboxConfig
        property string card: ofonoSimManager.cardIdentifier != "" ? ofonoSimManager.cardIdentifier : "default"
        key: "/sailfish/voicecall/voice_mailbox/" + card
        defaultValue: ""
    }
}
