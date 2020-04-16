/*
 * Copyright (c) 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Settings.Networking 1.0
import Sailfish.Silica.private 1.0 as Private

Dialog {
    property bool edit
    property alias network: networkField.text
    property alias netmask: netmaskField.text
    property alias gateway: gatewayField.text

    canAccept: !networkField.errorHighlight
               && !netmaskField.errorHighlight
               && !gatewayField.errorHighlight
               && network && gateway
    onAcceptBlocked: hightlightErrors()
    onAccepted: {
        autofillNetwork.save()
        autofillNetmask.save()
    }

    function hasErrors() {
        return networkField.errorHighlight
                || netmaskField.errorHighlight
                || gatewayField.errorHighlight
                || !network || !gateway
    }

    function hightlightErrors() {
        networkField.updateErrorHighlight()
        netmaskField.updateErrorHighlight()
        gatewayField.updateErrorHighlight()
    }

    Component.onCompleted: {
        // Include some obvious netmasks
        autofillNetmask.insert("255.0.0.0")
        autofillNetmask.insert("255.255.0.0")
        autofillNetmask.insert("255.255.255.0")
        networkField.focus = true
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            DialogHeader {
                              //: Header for page when editing a user route
                              //% "Edit user route"
                title: edit ? qsTrId("settings_network-he_edit user_route")
                              //: Header for page when adding a new user route
                              //% "Add user route"
                            : qsTrId("settings_network-he_add_user_route")
                //: Text used for the dialogue save button
                //% "Save"
                acceptText: qsTrId("settings_network-he_accept_save")
            }

            IPAddressField {
                id: networkField

                //: Example IP address for the network field
                //% "E.g. 192.168.1.10"
                placeholderText: qsTrId("settings_network-ph_example_network")
                //: Networking terminology
                //% "Network IP address"
                label: qsTrId("settings_network-la_network_ip_address")
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: netmaskField.focus = true

                Private.AutoFill {
                    id: autofillNetwork
                    key: "settings.vpn.routes.network"
                }
            }

            IPAddressField {
                id: netmaskField

                //: Example IP mask for the netmask field
                //% "E.g. 255.255.255.0"
                placeholderText: qsTrId("settings_network-ph_example_netmask")
                //: Networking terminology
                //% "Subnet mask"
                label: qsTrId("settings_network-la_subnet_mask")
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: gatewayField.focus = true
                emptyInputOk: true

                Private.AutoFill {
                    id: autofillNetmask
                    key: "settings.vpn.routes.netmask"
                }
            }

            IPAddressField {
                id: gatewayField

                //: Example IP address for the gateway field
                //% "E.g. 192.168.1.1"
                placeholderText: qsTrId("settings_network-ph_example_gateway")
                //: Networking terminology
                //% "Gateway"
                label: qsTrId("settings_network-la_gateway")
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: focus = false

                Private.AutoFill {
                    // network and gateway share an autofill database
                    key: "settings.vpn.routes.network"
                }
            }
        }

        VerticalScrollDecorator {}
    }
}
