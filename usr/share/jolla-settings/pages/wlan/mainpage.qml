import QtQuick 2.0
import MeeGo.Connman 0.2
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import com.jolla.settings 1.0
import Sailfish.Settings.Networking 1.0
import com.jolla.connection 1.0
import Nemo.DBus 2.0
import org.nemomobile.systemsettings 1.0

Page {
    id: mainPage

    property bool suppressScan
    property var _errorPlaceholder
    property bool showAddNetworkDialog
    property bool pageReady

    onStatusChanged: {
        if (status == PageStatus.Active) {
            pageReady = true
            if (showAddNetworkDialog) {
                showAddNetworkDialog = false

                var addNetworkProperties = networkHelper.readSettings()
                var dialog = pageStack.push(Qt.resolvedUrl("AddNetworkDialog.qml"), { networkManager: networkManager }, PageStackAction.Immediate)
                dialog.network.ssid = addNetworkProperties.ssid
                dialog.network.hidden = addNetworkProperties.hidden
                dialog.network.securityType = addNetworkProperties.securityType
                if (addNetworkProperties.eapMethod !== undefined)
                    dialog.network.eapMethod = addNetworkProperties.eapMethod
                if (addNetworkProperties.phase2)
                    dialog.network.phase2 = addNetworkProperties.phase2
                dialog.network.identity = addNetworkProperties.identity
                dialog.network.passphrase = addNetworkProperties.passphrase
                if (addNetworkProperties.caCert) {
                    dialog.network.caCert = addNetworkProperties.caCert
                } else if (addNetworkProperties.caCertFile) {
                    dialog.network.caCertFile = addNetworkProperties.caCertFile
                    if (addNetworkProperties.domainSuffixMatch)
                        dialog.network.domainSuffixMatch = addNetworkProperties.domainSuffixMatch
                }
                if (addNetworkProperties.privateKeyFile) {
                    dialog.network.privateKeyFile = addNetworkProperties.privateKeyFile
                }
                if (addNetworkProperties.clientCertFile) {
                    dialog.network.clientCertFile = addNetworkProperties.clientCertFile
                }

                dialog.accepted.connect(function() {
                    networkSetupLoader.active = true
                    networkSetupLoader.item.setup(dialog.path)
                })
            }
        }
    }

    AboutSettings {
        id: aboutSettings
    }

    AddNetworkHelper {
        id: networkHelper
    }

    SilicaListView {
        id: listView

        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                // Menu item for opening the advanced network configuration page
                //% "Advanced"
                text: qsTrId("settings_network-me-wlan_advanced")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("../advanced-networking/mainpage.qml"))
            }
            MenuItem {
                id: connectMenuItem
                //% "Connect to internet"
                text: qsTrId("settings_network-me-connect_to_internet")
                enabled: wifiListModel.powered
                onClicked: connectionSelector.openConnection()
            }
        }

        header: Column {
            width: parent.width
            enabled: AccessPolicy.wlanToggleEnabled

            PageHeader {
                //% "WLAN"
                title: qsTrId("settings_network-ph-wlan")
            }

            ListItem {
                id: enableItem

                visible: wifiListModel.available
                contentHeight: wifiSwitch.height
                openMenuOnPressAndHold: false

                IconTextSwitch {
                    id: wifiSwitch

                    property string entryPath: "system_settings/connectivity/wlan/enable_switch"

                    // label + padding + wlan icon + screen edge padding
                    automaticCheck: false
                    icon.source: "image://theme/icon-m-wlan"
                    checked: wifiListModel.available && wifiListModel.powered && !wifiTechnology.tethering
                    //% "WLAN"
                    text: qsTrId("settings_network-la-wlan")
                    enabled: AccessPolicy.wlanToggleEnabled && (!wifiTechnology.tethering || AccessPolicy.internetSharingEnabled)
                    description: {
                        if (!AccessPolicy.wlanToggleEnabled) {
                            if (checked) {
                                //: %1 is an operating system name without the OS suffix
                                //% "Enabled by %1 Device Manager"
                                return qsTrId("settings_network-la-enabled_by_mdm")
                                    .arg(aboutSettings.baseOperatingSystemName)
                            } else {
                                //: %1 is an operating system name without the OS suffix
                                //% "Disabled by %1 Device Manager"
                                return qsTrId("settings_network-la-disabled_by_mdm")
                                    .arg(aboutSettings.baseOperatingSystemName)
                            }
                        } else {
                            return ""
                        }
                    }

                    onClicked: {
                        if (wifiTechnology.tethering)
                            connectionAgent.stopTethering(true)
                        else
                            wifiListModel.powered = !wifiListModel.powered
                    }
                }
            }

            InfoLabel {
                //% "Internet sharing is enabled. Turning WLAN networking on will stop Internet sharing"
                text: qsTrId("settings_network-la-wlan_internet_sharing_warning")
                visible: opacity > 0
                opacity: wifiTechnology.tethering ? 1 : 0
            }
        }

        section.property: "managed"
        section.delegate: Column {
            property bool managed: section === "true"

            width: parent.width
            visible: wifiListModel.available
            enabled: AccessPolicy.wlanToggleEnabled

            SectionHeader {
                text: {
                    if (managed) {
                        //% "Managed networks"
                        return qsTrId("settings_network-he-managed_networks")
                    } else {
                        //% "Saved networks"
                        return qsTrId("settings_network-he-saved_networks")
                    }
                }
            }
            Label {
                visible: managed
                wrapMode: Text.Wrap
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeSmall
                //: %1 is an operating system name without the OS suffix
                //% "Networks added by %1 Device Manager"
                text: qsTrId("settings_network-la-networks_added_by_mdm")
                    .arg(aboutSettings.baseOperatingSystemName)
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
            }
        }

        model: wifiListModel.available ? savedNetworks : null

        delegate: NetworkItemDelegate { width: parent.width }

        // This is shown when connman is completely broken
        Component {
            id: errorPlaceholderComponent
            ViewPlaceholder {
                opacity: wifiListModel.available || !pageReady ? 0 : 1
                visible: opacity > 0.0
                //: connection service has crashed.
                //% "Networking is unavailable. Please reboot"
                text: qsTrId("settings_network-la-connman_unavailable")
                Behavior on opacity { FadeAnimation {} }
            }
        }

        ViewPlaceholder {
            //% "Pull down to connect to internet"
            text: qsTrId("settings_network-ph-connect")
            enabled: wifiListModel.available && listView.count == 0 && connectMenuItem.enabled && !startupTimer.running
        }

        VerticalScrollDecorator {}
    }

    Timer {
        interval: 25000
        // Activate wifi Scan only when the page is visible, wifi technology is switched on
        // Scanning is used to keep the signal strength of the saved services up-to-date, this may
        // not be absolutely necessary.
        running: ((mainPage.status === PageStatus.Activating || mainPage.status === PageStatus.Active) &&
                  wifiListModel.available && wifiListModel.powered && Qt.application.state === Qt.ApplicationActive)
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!mainPage.suppressScan) {
                wifiListModel.requestScan()
            }
        }
    }

    Timer {
        id: startupTimer
        interval: 1000
        running: true
    }

    TechnologyModel {
        id: wifiListModel

        name: "wifi"

        onAvailableChanged: maybeCreateErrorPlaceHolder()
        Component.onCompleted: maybeCreateErrorPlaceHolder()

        function maybeCreateErrorPlaceHolder() {
            if (!wifiListModel.available && !_errorPlaceholder)
                _errorPlaceholder = errorPlaceholderComponent.createObject(listView)
        }
    }

    SavedServiceModel {
        id: savedNetworks
        name: "wifi"
        sort: true
        groupByCategory: true
    }

    NetworkTechnology {
        id: wifiTechnology
        path: networkManager.WifiTechnology
    }

    NetworkManager {
        id: networkManager
    }

    ConnectionAgent { id: connectionAgent }

    Loader {
        id: networkSetupLoader
        sourceComponent: AddNetworkNotifications {
            onAvailableChanged: if (available) requestConnect() // a bit broken responsibility...
            timeout: true
        }
        active: false
    }

    DBusInterface {
        id: connectionSelector

        service: "com.jolla.lipstick.ConnectionSelector"
        path: "/"
        iface: "com.jolla.lipstick.ConnectionSelectorIf"

        function openConnection() {
            call('openConnectionNow', 'wifi')
        }
    }
}
