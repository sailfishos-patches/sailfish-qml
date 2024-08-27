import QtQuick 2.0
import Sailfish.Settings.Networking 1.0
import Nemo.Connectivity 1.0
import Nemo.DBus 2.0
import Connman 0.2
import com.jolla.connection 1.0

Item {
    property alias offlineMode: mobileData.offlineMode
    readonly property alias busy: delayedTetheringSwitch.running
    property alias active: wifiTechnology.tethering
    property alias identifier: wifiTechnology.tetheringId
    property alias passphrase: wifiTechnology.tetheringPassphrase
    readonly property bool roamingAllowed: !mobileData.roaming || mobileData.roamingAllowed
    property alias autoConnect: mobileData.autoConnect
    property alias valid: mobileData.valid


    function stopTethering() {
        delayedTetheringSwitch.start()
        connectionAgent.stopTethering("wifi")
    }

    function startTethering() {
        delayedTetheringSwitch.start()
        connectionAgent.startTethering("wifi")
    }

    function requestMobileData() {
        if (mobileData.slotIndex != -1) {
            connectionSelector.openConnection()
            return true
        }
        return false
    }

    function generatePassphrase() {
        return _randomString(8)
    }

    function _randomString(stringLength) {
        var chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz"
        var str = ''
        for (var i = 0; i < stringLength; i++) {
            var rnum = Math.floor(Math.random() * chars.length)
            str += chars.charAt(rnum)
        }
        return str
    }

    NetworkingMobileDataConnection {
        id: mobileData
        useDefaultModem: true
        objectName: "MobileDataWifiTethering"
    }

    Timer {
        id: delayedTetheringSwitch
        interval: 15000
    }

    ConnectionAgent {
        id: connectionAgent
        onWifiTetheringFinished: delayedTetheringSwitch.stop()
    }

    NetworkManager {
        id: networkManager
    }

    NetworkTechnology {
        id: wifiTechnology
        path: networkManager.WifiTechnology
    }

    DBusInterface {
        id: connectionSelector

        service: "com.jolla.lipstick.ConnectionSelector"
        path: "/"
        iface: "com.jolla.lipstick.ConnectionSelectorIf"

        function openConnection() {
            call('openConnectionNow', 'cellular')
        }
    }
}
