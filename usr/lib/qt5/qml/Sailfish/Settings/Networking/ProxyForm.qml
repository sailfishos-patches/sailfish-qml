/*
 * Copyright (c) 2021 - 2022 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

Column {
    id: root
    property QtObject network
    property alias currentIndex: proxyCombo.currentIndex
    property alias proxyLoader: proxyLoader
    property alias comboLabel: proxyCombo.label

    width: parent.width
    opacity: enabled ? 1.0 : Theme.opacityLow

    function methodStringToInteger(method) {
        if (method === "manual") {
            return 1
        } else if (method === "auto") {
            return 2
        } else {
            // "direct"
            return 0
        }
    }

    function proxyConfigToInteger(currentIndex, proxyConfig, proxy) {
        // On initialisation use the readonly proxy values if they exists
        var configIndex = methodStringToInteger(proxy ? proxy["Method"] : proxyConfig["Method"])

        // The "auto" method is either "auto-detect" (2) or "auto-config" (3) depending
        // on whether an explicit URL is set, or the combobox was set by the user
        if (configIndex === 2) {
            if (proxyConfig["URL"] || currentIndex === 3) {
                configIndex = 3
            }
        }

        // If "manual" is set by the user, it will identify as "none" until some explicit proxy
        // details are configured, so we should show it as "direct" in the meantime
        if ((configIndex === 0) && (currentIndex === 1)) {
            configIndex = 1
        }
        return configIndex
    }

    Connections {
        target: network
        onProxyConfigChanged: {
            var configIndex = proxyConfigToInteger(proxyCombo.currentIndex, network.proxyConfig, null)
            if (proxyCombo.currentIndex !== configIndex) {
                proxyLoader.focus = false
                proxyCombo.currentIndex = configIndex
            }
            if (configIndex === 1) {
                proxyLoader.item.reset()
            }
        }
    }

    ComboBox {
        id: proxyCombo

        onCurrentIndexChanged: {
            var proxyConfig = network.proxyConfig

            switch (currentIndex) {
            case 0:
                proxyConfig["Method"] = "direct"
                break
            case 1:
                proxyConfig["Method"] = "manual"
                break
            case 2:
                proxyConfig["Method"] = "auto"
                proxyConfig["URL"] = ""
                break
            case 3:
                proxyConfig["Method"] = "auto"
                break
            }
            network.proxyConfig = proxyConfig
        }

        Component.onCompleted: {
            currentIndex = proxyConfigToInteger(proxyCombo.currentIndex, network.proxyConfig, network.proxy)
        }

        //: Referring to the network proxy method to use for this connection
        //% "Proxy configuration"
        label: qsTrId("settings_network-la-proxy_configuration")
        menu: ContextMenu {
            MenuItem {
                //% "Disabled"
                text: qsTrId("settings_network-me-proxy_disabled")
            }
            MenuItem {
                //% "Manual"
                text: qsTrId("settings_network-me-proxy_manual")
            }
            MenuItem {
                //% "Auto-detect"
                text: qsTrId("settings_network-me-proxy_auto_detect")
            }
            MenuItem {
                //% "Auto config URL"
                text: qsTrId("settings_network-me-proxy_auto_config")
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
                return autoDetectProxy
            } else if (index === 3) {
                return autoConfigProxy
            }
        }
    }

    // Workaround for Loader not resetting its height when sourceComponent is undefined
    Component {
        id: fakeEmptyItem

        Item {}
    }

    Component {
        id: manualProxy

        ManualProxyForm { network: root.network }
    }

    Component {
        id: autoDetectProxy

        AutoDetectProxyForm { network: root.network }
    }

    Component {
        id: autoConfigProxy

        AutoConfigProxyForm { network: root.network }
    }
}
