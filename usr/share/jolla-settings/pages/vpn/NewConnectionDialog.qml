import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Settings.Networking.Vpn 1.0
import Sailfish.Settings.Networking 1.0
import Qt.labs.folderlistmodel 2.1

Dialog {
    id: root

    property Page mainPage

    canAccept: false
    forwardNavigation: false
    acceptDestinationAction: PageStackAction.Pop

    FolderListModel {
        id: vpnTypes
        folder: VpnTypes.settingsPath
        showFiles: false
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        VerticalScrollDecorator { }

        Column {
            id: content
            width: parent.width

            opacity: vpnTypes.count > 0 ? 1 : 0
            Behavior on opacity { FadeAnimation {} }

            DialogHeader {
                id: pageHeader

                //% "Please select a VPN type"
                title: qsTrId("settings_network-he-vpn_type_select")

                acceptText: ''
            }

            Item { width: 1; height: Theme.paddingLarge }

            Repeater {
                model: vpnTypes

                delegate: Loader {
                    source: filePath + "/" + "listitem.qml"
                    width: root.width
                    onItemChanged: if (item) item._mainPage = mainPage
                }
            }
        }

        ViewPlaceholder {
            //: Shown when no plugins for configuring the VPNs are installed
            //% "There are no VPN providers installed."
            text: qsTrId("settings_network-ph-vpn_no_plugins_text")
            //: Shown when no plugins for configuring the VPNs are installed
            //% "Install a VPN plugin to configure a new VPN"
            hintText: qsTrId("settings_network-ph-vpn_no_plugins_hint")
            enabled: opacity > 0.0
            opacity: ((root.status < 2) || vpnTypes.count > 0) ? 0 : 1
            Behavior on opacity { FadeAnimation {} }
        }
    }
}

