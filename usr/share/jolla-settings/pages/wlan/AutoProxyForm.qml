import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Settings.Networking 1.0

Column {
    id: form

    property QtObject network

    property bool updating
    property bool _completed
    property bool _updateRequired

    Connections {
        target: network
        onProxyConfigChanged: timer.restart()
    }

    Timer {
        id: timer

        interval: 1
        onTriggered: {
            form.updating = false
            if (form._updateRequired)
                updateAutoProxy()
        }
    }

    function updateAutoProxyIfAcceptable() {
        if (!_completed)
            return

        if (urlField.acceptableInput)
            _updateRequired = true

        if (!updating && _updateRequired)
            updateAutoProxy()
    }

    function updateAutoProxy() {
        var proxyConfig = network.proxyConfig

        proxyConfig["Method"] = "auto"
        proxyConfig["Servers"] = []

        if (urlField.validProtocol) {
            proxyConfig["URL"] = urlField.text
        } else {
            proxyConfig["URL"] = "https://" + urlField.text
        }

        updating = true
        _updateRequired = false
        network.proxyConfig = proxyConfig
    }

    Component.onCompleted: _completed = true

    NetworkAddressField {
        id: urlField

        focus: true
        text: network.proxyConfig["URL"] ? network.proxyConfig["URL"] : ""
        onActiveFocusChanged: if (!activeFocus) updateAutoProxyIfAcceptable()

        //: Keep short, placeholder label that cannot wrap
        //% "E.g. https://example.com/proxy.pac"
        placeholderText: qsTrId("settings_network-la-automatic_proxy_address_example")

        //% "Proxy address"
        label: qsTrId("settings_network-la-proxy_address")

        EnterKey.iconSource: "image://theme/icon-m-enter-close"
        EnterKey.onClicked: parent.focus = true
    }
}
