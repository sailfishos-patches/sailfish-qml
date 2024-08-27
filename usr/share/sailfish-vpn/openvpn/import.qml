import QtQuick 2.0
import Sailfish.Settings.Networking.Vpn 1.0
import Nemo.Connectivity 1.0 as Connectivity

QtObject {
    property string mimeType: 'application/x-openvpn'
    property string vpnType: 'openvpn'
    function parseFile(fileName) {
        return Connectivity.SettingsVpnModel.processProvisioningFile(fileName, "openvpn")
    }
}
