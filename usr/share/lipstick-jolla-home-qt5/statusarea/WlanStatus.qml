import QtQml 2.2
import com.jolla.lipstick 0.1
import MeeGo.Connman 0.2

QtObject {
    id: wlan

    readonly property string path: "system_settings/connectivity/wlan/enable_switch"
    readonly property bool enabled: wlanNetworkTechnology.powered
    readonly property bool connected: enabled && wlanNetworkTechnology.connected

    property NetworkTechnology wlanNetworkTechnology: NetworkTechnology {
        path: ConnectionManager.wifiPath
    }
}
