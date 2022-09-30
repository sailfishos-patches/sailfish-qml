import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Settings.Networking 1.0
import Sailfish.Settings.Networking.Vpn 1.0

VpnImportDialog {
    //% "Import PPTP .pbk file"
    title: qsTrId("settings_network-he-vpn_import_pptp")
    //% "Import PPTP .pbk file failed"
    failTitle: qsTrId("settings_network-he-vpn_import_pptp_failed")

    //% "Importing a file makes the set up process easier by filling out many options automatically."
    //% "<br>Choose 'Skip' to set up PPTP manually."
    message: qsTrId("settings_network-he-vpn_import_pptp_desc")
    //% "Choose 'Try again' to choose another file, or choose 'Skip' to set up PPTP manually."
    failMessage: qsTrId("settings_network-he-vpn_import_pptp_failed_desc")

    nameFilters: ['*.pbk']
}
