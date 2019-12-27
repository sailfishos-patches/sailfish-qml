import QtQuick 2.6
import Sailfish.Silica 1.0

Column {
    id: root
    property QtObject network
    property alias currentIndex: proxyCombo.currentIndex
    property alias proxyLoader: proxyLoader

    width: parent.width
    opacity: enabled ? 1.0 : Theme.opacityLow

    function methodStringToInteger(method) {
        if (method === "manual") {
            return 1
        } else if (method === "auto") {
            return 2
        } else {
            return 0
        }
    }

    Connections {
        target: network
        onProxyConfigChanged: {
            var configIndex = methodStringToInteger(network.proxyConfig["Method"])
            if (proxyCombo.currentIndex !== configIndex) {
                proxyLoader.item.updating = true
                proxyLoader.focus = false
                proxyCombo.currentIndex = configIndex
            }
        }
    }

    ComboBox {
        id: proxyCombo

        onCurrentIndexChanged: {
            var proxyConfig = network.proxyConfig
            proxyLoader.item.updating = true

            if (currentIndex === 0) {
                proxyConfig["Method"] = "direct"
                network.proxyConfig = proxyConfig
            }
        }

        Component.onCompleted: {
            var method = network.proxyConfig["Method"]

            currentIndex = methodStringToInteger(method)
        }

        //: Referring to the network proxy method to use for this connection
        //% "Proxy configuration"
        label: qsTrId("settings_network-la-proxy_configuration")
        menu: ContextMenu {
            MenuItem {
                //% "No proxies"
                text: qsTrId("settings_network-me-no_proxies")
            }
            MenuItem {
                //% "Manual"
                text: qsTrId("settings_network-me-manual")
            }
            MenuItem {
                //% "Automatic"
                text: qsTrId("settings_network-me-automatic")
            }
        }
    }

    Loader {
        id: proxyLoader
        width: parent.width
        sourceComponent: {
            var index = proxyCombo.currentIndex
            if (index === 0) {
                return fakeEmptyItem
            } else if (index === 1) {
                return manualProxy
            } else if (index === 2) {
                return autoProxy
            }
        }
    }

    // this is a workaround for Loader not reseting its height when sourceComponent is undefined
    Component {
        id: fakeEmptyItem

        Item {
            property bool updating: false
        }
    }

    Component {
        id: manualProxy

        ManualProxyForm { network: root.network }
    }

    Component {
        id: autoProxy

        AutoProxyForm { network: root.network }
    }
}
