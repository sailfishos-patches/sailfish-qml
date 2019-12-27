import QtQml 2.2
import org.freedesktop.contextkit 1.0

ContextProperty {
    id: flightMode

    readonly property string path: "system_settings/connectivity/flight/enable_switch"
    readonly property bool enabled: !value
    readonly property alias connected: flightMode.enabled

    // System.InternetEnabled is MCE master radio switch
    key: "System.InternetEnabled"
}
