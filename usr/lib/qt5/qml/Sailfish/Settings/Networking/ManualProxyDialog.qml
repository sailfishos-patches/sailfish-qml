/*
 * Copyright (c) 2022 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Settings.Networking 1.0

Dialog {
    property alias address: addressField.text
    property alias port: portField.text
    property bool edit

    canAccept: !hasErrors()
    onAcceptBlocked: {
        addressField.updateErrorHighlight()
        portField.updateErrorHighlight()
    }
    onRejected: {
        // Prevent fields being highlighting on cancel
        addressField.acceptableInput = true
        portField.acceptableInput = true
    }

    function hasErrors() {
        return !addressField.acceptableInput || !portField.acceptableInput
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            DialogHeader {
                title: edit
                         //% "Edit manual proxy"
                       ? qsTrId("settings_network-he_edit_manual_proxy")
                         //% "Add manual proxy"
                       : qsTrId("settings_network-he_add_manual_proxy")
                //: Text used for the dialogue save button
                //% "Save"
                acceptText: qsTrId("settings_network-he_accept_save")
            }

            NetworkAddressField {
                id: addressField
                focus: true

                //: Keep short, placeholder label that cannot wrap
                //% "E.g. http://proxy.example.com"
                placeholderText: qsTrId("settings_network-la-manual_proxy_address_example")

                //% "Proxy address"
                label: qsTrId("settings_network-la-proxy_address")

                text: network.proxyConfig["Servers"] ? network.proxyConfig["URL"] : network.proxy["URL"]

                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: portField.focus = true
            }

            IpPortField {
                id: portField

                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: accept()
            }
        }

        VerticalScrollDecorator {}
    }
}
