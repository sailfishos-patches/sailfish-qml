import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Settings.Networking 1.0
import Sailfish.Settings.Networking.Vpn 1.0

VpnImportDialog {
    //% "Import Fortinet config file"
    title: qsTrId("settings_network-he-vpn_import_openfortivpn")
    //% "Import of Fortinet config file failed"
    failTitle: qsTrId("settings_network-he-vpn_import_openfortivpn_failed")

    //% "Use either forticlient .conn or openfortivpn config file. "
    //% "Importing a file makes the set up process easier by filling out many options automatically."
    //% "<br><br>Choose 'Skip' to set up openfortivpn manually."
    message: qsTrId("settings_network-he-vpn_import_openfortivpn_desc")
    //% "Choose 'Try again' to choose another file, or choose 'Skip' to set up openfortivpn manually."
    failMessage: qsTrId("settings_network-he-vpn_import_openfortivpn_failed_desc")

    nameFilters: [ '*.conn', '*.conf' ]
}
