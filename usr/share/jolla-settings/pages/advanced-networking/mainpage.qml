import QtQuick 2.6
import Nemo.DBus 2.0
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import com.jolla.settings.system 1.0
import Sailfish.Settings.Networking 1.0
import "../wlan"

Page {
    id: root
    property NetProxyConfig netProxy: NetProxyConfig {}

    DBusInterface {
         id: hostnameDBus
         property string hostname
         iface: 'org.freedesktop.hostname1'

         signalsEnabled: true
         bus: DBus.SystemBus
         service: 'org.freedesktop.hostname1'
         path: '/org/freedesktop/hostname1'

         function get() {
             hostname = hostnameDBus.getProperty("StaticHostname")
         }

         function set(name) {
             hostnameDBus.call('SetStaticHostname', [name, true], function () {
                 hostnameDBus.hostname = name
             }, function (result) {
                 console.warn("Error during setting hostname - " + result)
                 textField.text = hostnameDBus.hostname
             })
         }
         onPropertiesChanged: get()
     }

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

            TextField {
                id: textField

                property var regexp: new RegExp(/^([a-zA-Z]([a-zA-Z0-9\-\.]{0,252})[a-zA-Z0-9]) *$/)

                text: hostnameDBus.hostname
                //% "Hostname"
                label: qsTrId("advanced_networking-la-hostname")
                placeholderText: label
                acceptableInput: regexp.test(text)

                //% "Device name visible to other devices within the local network"
                description: qsTrId("advanced_networking-la-hostname_description")
                readOnly: !PolicyValue.DeveloperModeSettingsEnabled

                onActiveFocusChanged: {
                    var trimmed = text.trim()
                    if (!activeFocus && trimmed != hostnameDBus.hostname) {
                        hostnameDBus.set(trimmed)
                    }
                }
                EnterKey.onClicked: focus = false
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"

                Component.onCompleted: hostnameDBus.get()
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

