import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import com.jolla.settings.system 1.0
import Sailfish.Settings.Networking 1.0
import "../wlan"

Page {
    id: root
    property NetProxyConfig netProxy: NetProxyConfig {}

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: advancedColumn.height + Theme.paddingLarge

        VerticalScrollDecorator {}

        Column {
            id: advancedColumn
            width: parent.width
            enabled: !disabledByMdmBanner.active

            PageHeader {
                //% "Advanced"
                title: qsTrId("settings_network-he-advanced")
            }

            SectionHeader {
                //% "Global proxy"
                text: qsTrId("settings_network-he-global-proxy")
            }

            DisabledByMdmBanner {
                id: disabledByMdmBanner
                active: !AccessPolicy.networkProxySettingsEnabled
            }

            IconTextSwitch {
                id: netProxySwitch

                automaticCheck: false
                enabled: AccessPolicy.networkProxySettingsEnabled
                checked: netProxy.proxyActive
                busy: netProxy.busy
                //% "Global proxy"
                text: qsTrId("settings_network-la-global-proxy")
                // Applies the "Proxy configuration" settings lower down the same page to all network connections
                //% "Is used for all connections (WLAN, mobile, ...) and overrides individual settings."
                description: qsTrId("settings_network-la-global-proxy-description")
                icon.source: "image://theme/icon-m-global-proxy"

                onClicked: {
                    netProxy.proxyActive = !netProxySwitch.checked
                }
            }

            ProxyForm {
                id: proxyForm
                network: netProxy
                enabled: !disabledByMdmBanner.active
            }
        }
    }
}

