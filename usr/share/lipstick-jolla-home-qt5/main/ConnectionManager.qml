pragma Singleton
import QtQuick 2.2
import MeeGo.Connman 0.2

QtObject {
    property alias cellularPath: networkManager.CellularTechnology
    property alias wifiPath: networkManager.WifiTechnology

    property alias available: networkManager.available
    property alias connectionState: networkManager.state
    property alias defaultRoute: networkManager.defaultRoute
    property alias connectedWifi: networkManager.connectedWifi
    property alias connectingWifi: networkManager.connectingWifi

    property alias offlineMode: networkManager.offlineMode

    function servicesList(technology) {
        return networkManager.servicesList(technology)
    }

    function createServiceSync(settings, technology, service, device) {
        return networkManager.createServiceSync(settings, technology, service, device)
    }

    // ConnectionSelector: uses only for offlineMode and createServiceSync
    // StatusArea: uses servicesList, available, and defaultRoute (NetworkService).
    // Do not toggle state of servicesEnabled based on state of layers of home.
    // When / if servicesEnabled is disabled all NetworkService are cleared causing
    // default route lookup when it is enabled again => expesive operation and
    // cannot happen frequently.
    // Thus, keep servicesEnabled all the time.

    // As this is a singleton we do not get heat from multiple places
    // with many WLAN access points.
    property NetworkManager _networkManager: NetworkManager {
        id: networkManager
        technologiesEnabled: false
    }
}
