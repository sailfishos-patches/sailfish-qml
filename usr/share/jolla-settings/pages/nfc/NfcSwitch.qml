import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0
import com.jolla.settings.system 1.0
import com.jolla.settings 1.0

SettingsToggle {
    //% "NFC"
    name: qsTrId("settings_nfc_switch-la-nfc")
    icon.source: "image://theme/icon-m-nfc"
    onToggled: nfcConfig.toggleNfcEnabled()
    checked: nfcConfig.nfcEnabled
    busy: nfcConfig.busy

    NfcConfig {
        id: nfcConfig
    }
}
