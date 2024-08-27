import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.voicecall.settings.translations 1.0
import Nemo.Notifications 1.0
import Nemo.Configuration 1.0
import QOfono 0.2

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

    TextField {
        id: mailboxEditor

        text: voiceMailboxNumber
        inputMethodHints: Qt.ImhDialableCharactersOnly
        //% "Voicemail number"
        label: qsTrId("settings_phone-la-voicemail_number")
        visible: ofonoMessageWaiting.ready && ofonoSimManager.present

        EnterKey.iconSource: "image://theme/icon-m-enter-close"
        EnterKey.onClicked: focus = false
        onActiveFocusChanged: applySettings()

        rightItem: IconButton {
            onClicked: {
                mailboxConfig.value = ""
                mailboxEditor.text = voiceMailboxNumber
            }

            width: icon.width
            height: icon.height
            icon.source: "image://theme/icon-splus-clear"
            enabled: mailboxEditor.text != ofonoMessageWaiting.voicemailMailboxNumber
            opacity: enabled ? 1.0 : 0.0
            Behavior on opacity { FadeAnimation {} }
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
