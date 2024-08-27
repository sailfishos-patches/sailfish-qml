import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import Sailfish.Settings.Networking 1.0 as Networking
import Connman 0.2
import Nemo.Configuration 1.0
import Nemo.DBus 2.0
import com.jolla.connection 1.0
import com.jolla.settings 1.0

SettingsToggle {
    id: ethernetSwitch

    //% "Ethernet"
    name: qsTrId("settings_network-la-ethernet")
    activeText: networkManager.connectedEthernet ? networkManager.connectedEthernet.name : ""
    icon.source: active && networkManager.connectedEthernet
            ? "image://theme/icon-m-lan" : "image://theme/icon-m-lan"

    available: AccessPolicy.ethernetToggleEnabled
    active: ethernetTechnology && ethernetTechnology.connected
    checked: ethernetTechnology.powered
    busy: busyTimer.running

    menu: ContextMenu {
        SettingsMenuItem {
            onClicked: ethernetSwitch.goToSettings()
        }

        MenuItem {
            //% "Connect to internet"
            text: qsTrId("settings_network-me-ethernet-connect_to_internet")
            onClicked: connectionSelector.openConnection()
        }
    }

    onToggled: {
        // No accesspolicy for ethernet yet
        //if (!AccessPolicy.ethernetToggleEnabled) {
        //    errorNotification.notify(SettingsControlError.BlockedByAccessPolicy)
        if (networkManager.technologiesList().indexOf("ethernet") < 0) {
            errorNotification.notify(SettingsControlError.NoEthernetDevice)
        } else {
            ethernetTechnology.powered = !ethernetTechnology.powered
            if (ethernetTechnology.powered) {
                busyTimer.stop()
            } else if (connDialogConfig.rise) {
                busyTimer.restart()
            }
        }
    }

    Timer {
        id: busyTimer
        interval: connDialogConfig.scanningWait
        onTriggered: connectionSelector.openConnection()
        onRunningChanged: {
            if (running) {
                ethernetTechnology.connectedChanged.connect(stop)
            } else {
                ethernetTechnology.connectedChanged.disconnect(stop)
            }
        }
    }

    ConfigurationGroup {
        id: connDialogConfig

        // TODO: separate for ethernet?
        path: "/apps/jolla-settings/wlan_fav_switch_connection_dialog"

        property bool rise: true
        property int scanningWait: 5000
    }

    NetworkTechnology {
        id: ethernetTechnology
        path: networkManager.EthernetTechnology
    }

    NetworkManager { id: networkManager }

    ConnectionAgent { id: connectionAgent }

    DBusInterface {
        id: connectionSelector

        service: "com.jolla.lipstick.ConnectionSelector"
        path: "/"
        iface: "com.jolla.lipstick.ConnectionSelectorIf"

        function openConnection() {
            call('openConnectionNow', 'ethernet')
        }
    }
}
