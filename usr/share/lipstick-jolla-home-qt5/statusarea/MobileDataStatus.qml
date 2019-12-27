import QtQml 2.2
import com.jolla.lipstick 0.1
import MeeGo.Connman 0.2

QtObject {
    id: mobileData

    readonly property string path: "system_settings/connectivity/mobile/context0"
    readonly property bool enabled: mobileNetworkTechnology.powered
    readonly property bool connected: enabled && mobileNetworkTechnology.connected

    property NetworkTechnology mobileNetworkTechnology: NetworkTechnology {
        path: ConnectionManager.cellularPath
    }
}
