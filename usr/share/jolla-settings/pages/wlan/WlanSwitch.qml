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
    id: wifiSwitch

    //% "WLAN"
    name: qsTrId("settings_network-la-wlan")
    activeText: networkManager.connectedWifi ? networkManager.connectedWifi.name : ""
    icon.source: active && networkManager.connectedWifi
            ? "image://theme/icon-m-wlan-" + Networking.WlanUtils.getStrengthString(networkManager.connectedWifi.strength)
            : "image://theme/icon-m-wlan"

    available: AccessPolicy.wlanToggleEnabled
    active: wifiTechnology && wifiTechnology.connected
    checked: wifiTechnology.powered && !wifiTechnology.tethering
    busy: busyTimer.running

    menu: ContextMenu {
        SettingsMenuItem {
            onClicked: wifiSwitch.goToSettings()
        }

        MenuItem {
            //% "Connect to internet"
            text: qsTrId("settings_network-me-connect_to_internet")
            onClicked: connectionSelector.openConnection()
        }
    }

    onToggled: {
        if (!AccessPolicy.wlanToggleEnabled) {
            errorNotification.notify(SettingsControlError.BlockedByAccessPolicy)
        } else if (wifiTechnology.tethering) {
            connectionAgent.stopTethering("wifi", true)
        } else {
            wifiTechnology.powered = !wifiTechnology.powered
            if (wifiTechnology.powered) {
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
                wifiTechnology.connectedChanged.connect(stop)
            } else {
                wifiTechnology.connectedChanged.disconnect(stop)
            }
        }
    }

    ConfigurationGroup {
        id: connDialogConfig

        path: "/apps/jolla-settings/wlan_fav_switch_connection_dialog"

        property bool rise: true
        property int scanningWait: 5000
    }

    NetworkTechnology {
        id: wifiTechnology
        path: networkManager.WifiTechnology
    }

    NetworkManager { id: networkManager }

    ConnectionAgent { id: connectionAgent }

    DBusInterface {
        id: connectionSelector

        service: "com.jolla.lipstick.ConnectionSelector"
        path: "/"
        iface: "com.jolla.lipstick.ConnectionSelectorIf"

        function openConnection() {
            call('openConnectionNow', 'wifi')
        }
    }
}
