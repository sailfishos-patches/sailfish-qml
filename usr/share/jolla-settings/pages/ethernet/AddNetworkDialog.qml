import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import Sailfish.Settings.Networking 1.0
import Connman 0.2

Dialog {
    id: root

    property NetworkManager networkManager
    canAccept: true

    property string path
    onAccepted: {
        root.forceActiveFocus() // proxy and ipv4 fields update on focus lost
        path = networkManager.createServiceSync(network.json())
    }


    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge
        Column {
            id: column

            width: parent.width
            DialogHeader {
                dialog: root
                //% "Add network"
                title: qsTrId("settings_network-he-ethernet-add_network")
                //% "Save"
                acceptText: qsTrId("settings_network-he-ethernet-save")
            }

            AdvancedSettingsColumn {
                id: advancedSettingsColumn
                network: root.network
            }
        }

        VerticalScrollDecorator {}
    }
}
