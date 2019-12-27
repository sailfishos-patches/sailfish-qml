import QtQuick 2.0
import Sailfish.Silica 1.0
import MeeGo.Connman 0.2

ComboBox {
    //% "PEAP version"
    label: qsTrId("settings_network-la-peap_version")
    visible: network && network.securityType === NetworkService.SecurityIEEE802 && network.eapMethod === NetworkService.EapPEAP
    currentIndex: network && network.peapVersion !== undefined ? network.peapVersion + 1 : 0

    property QtObject network

    onCurrentIndexChanged: network.peapVersion = currentIndex - 1

    Binding on currentIndex {
        when: network && network.eapMethod !== NetworkService.EapPEAP
        value: 0
    }

    menu: ContextMenu {
        MenuItem {
            //% "Automatic"
            text: qsTrId("settings_network-va-encryption_peap_automatic")
        }
        MenuItem {
            //% "Version 0"
            text: qsTrId("settings_network-va-encryption_version0")
        }
        MenuItem {
            //% "Version 1"
            text: qsTrId("settings_network-va-encryption_version1")
        }
    }
}
