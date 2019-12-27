import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.DBus 2.0
import com.jolla.settings.system 1.0
import com.jolla.settings 1.0

Page {
    id: root

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content
            width: parent.width

            PageHeader {
                //% "NFC"
                title: qsTrId("settings_nfc-he-nfc")
            }

            IconTextSwitch {
                //% "Near Field Communication (NFC)"
                text: qsTrId("settings_nfc-la-nfc")
                //% "Allow device to detect NFC tags and other devices when touched. This feature consumes some battery power."
                description: qsTrId("settings_nfc-la-nfc_switch_description")
                icon.source: "image://theme/icon-m-nfc"
                onClicked: nfcConfig.toggleNfcEnabled()
                checked: nfcConfig.nfcEnabled
                automaticCheck: false
                busy: nfcConfig.busy
            }
        }
    }

    NfcConfig {
        id: nfcConfig
    }
}
