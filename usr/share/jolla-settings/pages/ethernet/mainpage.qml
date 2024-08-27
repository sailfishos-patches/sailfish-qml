import QtQuick 2.0
import Connman 0.2
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
    property bool techExists: false

    onStatusChanged: {
        if (status == PageStatus.Active) {
            pageReady = true
            if (showAddNetworkDialog) {
                showAddNetworkDialog = false

                var addNetworkProperties = networkHelper.readSettings()
                var dialog = pageStack.push(Qt.resolvedUrl("AddNetworkDialog.qml"), { networkManager: networkManager }, PageStackAction.Immediate)

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
                text: qsTrId("settings_network-me-ethernet_advanced")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("../advanced-networking/mainpage.qml"))
            }
            MenuItem {
                id: connectMenuItem
                //% "Connect to internet"
                text: qsTrId("settings_network-me-ethernet-connect_to_internet")
                enabled: ethernetListModel.powered
                onClicked: connectionSelector.openConnection()
            }
        }

        header: Column {
            width: parent.width
            enabled: true //AccessPolicy.ethernetToggleEnabled

            PageHeader {
                //% "Ethernet"
                title: qsTrId("settings_network-ph-ethernet")
            }

            ListItem {
                id: enableItem

                visible: techExists && ethernetListModel.available
                contentHeight: ethernetSwitch.height
                openMenuOnPressAndHold: false

                IconTextSwitch {
                    id: ethernetSwitch

                    property string entryPath: "system_settings/connectivity/ethernet/enable_switch"

                    // label + padding + ethernet icon + screen edge padding
                    automaticCheck: false
                    icon.source: "image://theme/icon-m-lan"
                    checked: ethernetListModel.available && ethernetListModel.powered
                    //% "Ethernet"
                    text: qsTrId("settings_network-la-ethernet")
                    enabled: true //AccessPolicy.ethernetToggleEnabled
                    //% "Fixed ethernet connection"
                    description: qsTrId("settings_network-la-ethernet_description") //{
//                        if (!AccessPolicy.ethernetToggleEnabled) {
//                            if (checked) {
                                //: %1 is an operating system name without the OS suffix
                                //% "Enabled by %1 Device Manager"
//                                return qsTrId("settings_network-la-ethernet-enabled_by_mdm")
//                                    .arg(aboutSettings.baseOperatingSystemName)
 //                           } else {
                                //: %1 is an operating system name without the OS suffix
                                //% "Disabled by %1 Device Manager"
//                                return qsTrId("settings_network-la-ethernet-disabled_by_mdm")
//                                    .arg(aboutSettings.baseOperatingSystemName)
//                            }
//                        } else {
//                            return ""
//                        }
//                    }

                    onClicked: {
                        ethernetListModel.powered = !ethernetListModel.powered
                    }
                }
            }
        }

        section.property: "managed"
        section.delegate: Column {
            property bool managed: section === "true"

            width: parent.width
            visible: techExists && ethernetListModel.available
            enabled: true //AccessPolicy.ethernetToggleEnabled

            SectionHeader {
                text: {
                    if (managed) {
                        //% "Managed networks"
                        return qsTrId("settings_network-he-ethernet-managed_networks")
                    } else {
                        //% "Saved networks"
                        return qsTrId("settings_network-he-ethernet-saved_networks")
                    }
                }
            }
            Label {
                visible: techExists && managed
                wrapMode: Text.Wrap
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeSmall
                //: %1 is an operating system name without the OS suffix
                //% "Networks added by %1 Device Manager"
                text: qsTrId("settings_network-la-ethernet-networks_added_by_mdm")
                    .arg(aboutSettings.baseOperatingSystemName)
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
            }
        }

        model: (techExists && ethernetListModel.available) ? savedServices : null

        delegate: EthernetItem { width: parent.width }

        // This is shown when there is no ethernet adapter.
        // ConnMan requires the adapter device to be present in order to allow
        // changes to tech and/or service(s).
        Component {
            id: errorPlaceholderComponent
            ViewPlaceholder {
                opacity: (techExists && ethernetListModel.available) || !pageReady ? 0 : 1
                visible: opacity > 0.0
                //% "Ethernet can be managed only when adapter is connected. Please connect adapter."
                text: qsTrId("settings_network-la-ethernet_unavailable")
                Behavior on opacity { FadeAnimation {} }
            }
        }

        ViewPlaceholder {
            //% "Pull down to connect to internet"
            text: qsTrId("settings_network-ph-ethernet-connect")
            enabled: ethernetListModel.available && listView.count == 0 && connectMenuItem.enabled && !startupTimer.running
        }

        VerticalScrollDecorator {}
    }

    Timer {
        id: startupTimer
        interval: 1000
        running: true
    }

    TechnologyModel {
        id: ethernetListModel

        name: "ethernet"

        onAvailableChanged: maybeCreateErrorPlaceHolder()
        Component.onCompleted: maybeCreateErrorPlaceHolder()

        function maybeCreateErrorPlaceHolder() {
            if ((!techExists || !ethernetListModel.available) && !_errorPlaceholder) {
                _errorPlaceholder = errorPlaceholderComponent.createObject(listView)
            }
        }
    }

    SavedServiceModel {
        id: savedServices
        name: "ethernet"
        sort: true
        groupByCategory: true
    }

    NetworkTechnology {
        id: ethernetTechnology
        path: networkManager.EthernetTechnology
    }

    NetworkManager {
        id: networkManager

        onTechnologiesChanged: checkEthernet()

        function checkEthernet() {
            // NOTE: something caches the values here as staying in the same view
            // there always exists a tech with "ethernet" name once it has been
            // connected. But when returning to main settings it is detected
            // correctly as NULL after removal is done. libconnman-qt does send
            // the signal correclty after removing the technology. Problem is
            // thus, somewhere in QML caching.
            techExists = networkManager.technologiesList().indexOf("ethernet") >= 0

            if (!techExists && !_errorPlaceholder) {
                _errorPlaceholder = errorPlaceholderComponent.createObject(listView)
            }
        }
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
            call('openConnectionNow', 'ethernet')
        }
    }
}
