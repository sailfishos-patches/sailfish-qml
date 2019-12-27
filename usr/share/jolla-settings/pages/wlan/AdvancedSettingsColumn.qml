import QtQuick 2.0
import Sailfish.Silica 1.0
import MeeGo.Connman 0.2
import com.jolla.settings.system 1.0
import Sailfish.Policy 1.0
import Sailfish.Settings.Networking 1.0
import "../netproxy"

Column {
    id: root
    property QtObject network

    property bool focusable: !!firstFocusableItem
    property Item firstFocusableItem: proxyForm.currentIndex > 0 ? proxyForm.proxyLoader
                                                                 : !ipv4Switch.checked ? ipv4FormLoader
                                                                                       : null
    property alias globalProxyButtonVisible: globalProxyButton.visible

    width: parent.width
    SectionHeader {
        //% "Proxies"
        text: qsTrId("settings_network-he-proxies")
    }

    DisabledByMdmBanner {
        id: disabledByMdmBanner
        active: !AccessPolicy.networkProxySettingsEnabled
    }

    Column {
        width: parent.width
        height: enabled ? implicitHeight + Theme.paddingLarge : 0
        spacing: Theme.paddingLarge
        enabled: netProxyConfig.proxyActive
        opacity: enabled ? 1.0 : 0.0

        Behavior on opacity { FadeAnimator { } }
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

        Label {
            width: parent.width - x * 2
            x: Theme.horizontalPageMargin
            color: Theme.secondaryHighlightColor
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.WordWrap
            //% "These proxy settings are currently being overridden by the global proxy settings."
            text: qsTrId("settings_network-la-proxy_is_overriding")
            opacity: disabledByMdmBanner.active ? Theme.opacityLow : 1.0
        }

        Button {
            id: globalProxyButton
            enabled: parent.enabled && !disabledByMdmBanner.active
            anchors.horizontalCenter: parent.horizontalCenter
            //: Button which opens the advanced settings page containing the global proxy config
            //% "Configure global proxy"
            text: qsTrId("settings_network-bt-configure_global_proxy")
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("../advanced-networking/mainpage.qml"))
        }
    }

    ProxyForm {
        id: proxyForm
        network: root.network
        enabled: !disabledByMdmBanner.active
    }

    SectionHeader {
        //% "IP address"
        text: qsTrId("settings_network-he-ip_address")
    }

    TextSwitch {
        id: ipv4Switch
        checked: network && network.ipv4Config["Method"] === "dhcp"
        //% "Auto-retrieve IP address"
        text: qsTrId("settings_network-bt-autoretrieve_ip")
        onCheckedChanged: {
            if (checked) {
                if (network.domainsConfig.length !== 0) {
                    network.domainsConfig = []
                }
                if (network.nameserversConfig.length !== 0) {
                    network.nameserversConfig = []
                }
                if (network.ipv4Config["Method"] !== "dhcp") {
                    network.ipv4Config = {"Method": "dhcp"}
                }
            }
        }
    }

    Loader {
        id: ipv4FormLoader
        width: parent.width
        sourceComponent: ipv4Switch.checked ? fakeEmptyItem : ipv4Form
    }

    Component {
        id: ipv4Form

        IPv4Form {
            network: root.network
        }
    }

    // this is a workaround for Loader not reseting its height when sourceComponent is undefined
    Component {
        id: fakeEmptyItem

        Item {
        }
    }

    NetProxyConfig {
        id: netProxyConfig
    }
}
