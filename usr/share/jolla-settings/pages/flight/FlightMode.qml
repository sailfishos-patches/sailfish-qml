import QtQuick 2.0
import Sailfish.Silica 1.0
import MeeGo.Connman 0.2
import Sailfish.Settings.Networking 1.0
import Nemo.KeepAlive 1.2

Item {
    property Item remorse
    property bool active: connMgr.instance.offlineMode
    KeepAlive {
        id: keepAlive
    }

    function setActive(_active) {
        if (active === _active) {
            return
        }

        // Hold keepalive session over offlineMode property change ipc
        keepAlive.enabled = true
        connMgr.instance.offlineMode = _active
    }

    NetworkManagerFactory {
        id: connMgr
    }
    Connections {
        target: connMgr.instance
        onOfflineModeChanged: {
            active = connMgr.instance.offlineMode
            // Operation succeeded - stop keepalive
            keepAlive.enabled = false
        }
    }
}
