import QtQuick 2.0
import Sailfish.Settings.Networking 1.0
import Nemo.Connectivity 1.0
import Nemo.DBus 2.0
import Connman 0.2
import com.jolla.connection 1.0

Item {
    readonly property alias busy: delayedTetheringSwitch.running
    property alias active: btTechnology.tethering
    property alias powered: btTechnology.powered

    function stopTethering() {
        delayedTetheringSwitch.start()
        connectionAgent.stopTethering("bluetooth", true)
    }

    function startTethering() {
        delayedTetheringSwitch.start()
        connectionAgent.startTethering("bluetooth")
    }

    Timer {
        id: delayedTetheringSwitch
        interval: 15000
    }

    ConnectionAgent {
        id: connectionAgent
        onBluetoothTetheringFinished: delayedTetheringSwitch.stop()
    }

    NetworkManager {
        id: networkManager
    }

    NetworkTechnology {
        id: btTechnology
        path: networkManager.BluetoothTechnology
    }
}
