import QtQuick 2.0
import Sailfish.Settings.Networking.Vpn 1.0
import org.nemomobile.systemsettings 1.0 as SystemSettings

QtObject {
    property string mimeType: 'application/x-vpnc'
    function parseFile(fileName) {
        return SystemSettings.SettingsVpnModel.processProvisioningFile(fileName, "vpnc")
    }
}
