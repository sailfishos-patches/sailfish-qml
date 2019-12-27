import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import Nemo.DBus 2.0
import com.jolla.settings 1.0
import Sailfish.Settings.Networking 1.0

SettingsToggle {
    id: root

    property NetProxyConfig netProxy: NetProxyConfig {}

    // The title used for the global proxy top menu switch
    //% "Global proxy"
    name: qsTrId("settings_network-la-global_proxy")
    icon.source: "image://theme/icon-m-global-proxy"

    available: AccessPolicy.networkProxySettingsEnabled
    busy: netProxy.busy
    checked: netProxy.proxyActive

    onToggled: {
        if (!AccessPolicy.networkProxySettingsEnabled) {
            errorNotification.notify(SettingsControlError.BlockedByAccessPolicy)
        } else {
            netProxy.proxyActive = !checked
        }
    }
}
