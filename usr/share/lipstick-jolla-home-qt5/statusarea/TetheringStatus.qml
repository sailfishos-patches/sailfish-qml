import QtQml 2.2
import org.freedesktop.contextkit 1.0

ContextProperty {
    id: tethering

    readonly property string path: "system_settings/connectivity/tethering/wlan_hotspot_switch"
    readonly property bool enabled: !!value
    readonly property alias connected: tethering.enabled

    key: "Internet.Tethering"
}
