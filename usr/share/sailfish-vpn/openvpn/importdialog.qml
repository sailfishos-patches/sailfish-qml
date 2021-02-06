import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Settings.Networking 1.0
import Sailfish.Settings.Networking.Vpn 1.0

VpnImportDialog {
    id: root
    nameFilters: [ '*.ovpn' ]

    //% "Import .ovpn file"
    title: qsTrId("settings_network-he-vpn_import_ovpn")
    //% "Import .ovpn file failed"
    failTitle: qsTrId("settings_network-he-vpn_import_ovpn_failed")

    //% "Importing a file makes the set up process easier by filling out many options automatically.<br>Choose 'Skip' to set up OpenVPN manually."
    message: qsTrId("settings_network-he-vpn_import_ovpn_desc")
    //% "Choose 'Try again' to choose another file, or choose 'Skip' to set up OpenVPN manually."
    failMessage: qsTrId("settings_network-he-vpn_import_ovpn_failed_desc")
}

