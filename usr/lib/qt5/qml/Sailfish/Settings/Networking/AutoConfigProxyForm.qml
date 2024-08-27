/*
 * Copyright (c) 2012 - 2022 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Settings.Networking 1.0

ListItem {
    property QtObject network

    contentHeight: Theme.itemSizeMedium

    function updateProxyConfig(url) {
        var proxyConfig = network.proxyConfig

        proxyConfig["Method"] = "auto"
        proxyConfig["URL"] = url

        network.proxyConfig = proxyConfig
    }

    Connections {
        target: network
        ignoreUnknownSignals: true
        onProxyChanged: {
            if (!network.proxyConfig["URL"] && network.proxy && network.proxy["URL"]) {
                urlField.text = network.proxy["URL"]
                updateProxyConfig(network.proxy["URL"])
            }
        }
    }

    NetworkAddressField {
        id: urlField

        onActiveFocusChanged: {
            if (!activeFocus && acceptableInput) {
                updateProxyConfig(text)
            }
        }

        text: network.proxyConfig["URL"] || ""

        //: Keep short, placeholder label that cannot wrap
        //% "E.g. https://example.com/proxy.pac"
        placeholderText: qsTrId("settings_network-la-automatic_proxy_address_example")

        //% "PAC URL"
        label: qsTrId("settings_network-la-proxy_pac_url")

        EnterKey.iconSource: "image://theme/icon-m-enter-close"
        EnterKey.onClicked: parent.focus = true
    }
}
