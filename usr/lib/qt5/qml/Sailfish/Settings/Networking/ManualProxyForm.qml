/*
 * Copyright (c) 2012 - 2022 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Settings.Networking 1.0
import "WlanUtils.js" as WlanUtils

Column {
    id: manualProxyRoot

    property QtObject network

    function reset() {
        var servers = network.proxyConfig["Servers"]
        repeater.model.clear()
        for (var i = 0; servers && i < servers.length; i++) {
            repeater.model.append({ "server": servers[i] })
        }
    }

    function updateProxyConfig() {
        var proxyExcludes
        var proxyConfig = network.proxyConfig

        if (repeater.model.count > 0) {
            proxyConfig["Method"] = "manual"
            proxyConfig["Servers"] = []

            for (var i = 0; i < repeater.model.count; i++) {
                proxyConfig["Servers"].push(repeater.model.get(i).server)
            }

            if (proxyExcludesField.acceptableInput) {
                proxyConfig["Excludes"] = proxyExcludesField.text.replace(" ", "").split(",")
            } else {
                proxyConfig["Excludes"] = []
            }
        } else {
            proxyConfig["Method"] = "direct"
        }

        network.proxyConfig = proxyConfig
    }

    function addManualProxy() {
        var obj = pageStack.animatorPush('ManualProxyDialog.qml', { address: "", port: "", edit: false })
        obj.pageCompleted.connect(function(page) {
            page.accepted.connect(function() {
                repeater.model.append({ "server": page.address + ":" + page.port })
                updateProxyConfig()
            })
        })
    }

    function setExcludes() {
        proxyExcludesField.text = WlanUtils.maybeJoin(network.proxyConfig["Excludes"])
    }

    Repeater {
        id: repeater
        model: ListModel {}

        Component.onCompleted: {
            reset()
        }

        delegate: ListItem {
            id: manualProxyItem
            contentHeight: Theme.itemSizeMedium

            function editManualProxy() {
                var pieces = server.split(":")
                var address = server
                var port = "0"
                if (server.length > 0 && !isNaN(parseInt(pieces[pieces.length - 1], 10))) {
                    port = pieces[pieces.length - 1]
                    address = address.slice(0, server.length - port.length - 1)
                }

                var obj = pageStack.animatorPush('ManualProxyDialog.qml', { address: address, port: port, edit: true })
                obj.pageCompleted.connect(function(page) {
                    page.accepted.connect(function() {
                        server = page.address + ":" + page.port
                        updateProxyConfig()
                    })
                })
            }

            menu: ContextMenu {
                MenuItem {
                    //: Menu option to edit a manual proxy entry
                    //% "Edit"
                    text: qsTrId("settings_network-me-manual_proxy_edit")
                    onClicked: editManualProxy()
                }
                MenuItem {
                    //: Menu option to delete a manual proxy entry
                    //% "Delete"
                    text: qsTrId("settings_network-me-manual_proxy_delete")
                    onDelayedClick: deleteManualProxy.start()
                }
            }

            PropertyAnimation {
                id: deleteManualProxy
                target: manualProxyItem
                properties: "contentHeight, opacity"
                to: 0
                duration: 200
                easing.type: Easing.InOutQuad
                onRunningChanged: {
                    if (running === false) {
                        // Keep a copy to avoid problems when we delete the item
                        var temp = manualProxyRoot
                        repeater.model.remove(model.index)
                        temp.updateProxyConfig()
                    }
                }
            }

            Label {
                id: manualProxyTitle
                x: Theme.horizontalPageMargin
                y: Theme.paddingMedium
                width: parent.width - 2 * x
                font.pixelSize: Theme.fontSizeMedium
                color: manualProxyItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                //: Title for the manual proxy "Proxy 1", "Proxy 2", etc.
                //% "Proxy %1"
                text: qsTrId("settings_network-la-manual_proxy_identifier").arg(index + 1)
            }
            Label {
                anchors.top: manualProxyTitle.bottom
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                font.pixelSize: Theme.fontSizeExtraSmall
                color: manualProxyItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                text: model.server
            }
            onClicked: openMenu()
        }
    }

    BackgroundItem {
        id: addManualProxyButton
        onClicked: addManualProxy()
        highlighted: down
        Icon {
            x: parent.width - (width + Theme.itemSizeSmall) / 2.0
            anchors.verticalCenter: parent.verticalCenter
            source: "image://theme/icon-m-add" + (parent.highlighted ? "?" + Theme.highlightColor : "")
        }
        Label {
            text: repeater.model.count === 0 ? //% "Add a proxy"
                                               qsTrId("settings_network-bu-manual_proxy_add_a_proxy")
                                             : //% "Add another proxy"
                                               qsTrId("settings_network-bu-manual_proxy_add_another_proxy")
            width: parent.width - Theme.iconSizeSmall - Theme.horizontalPageMargin
            x: Theme.horizontalPageMargin
            anchors.verticalCenter: parent.verticalCenter
            color: addManualProxyButton.highlighted ? Theme.highlightColor : Theme.primaryColor
        }
    }

    NetworkField {
        id: proxyExcludesField

        regExp: new RegExp( /^[\w- \.,]*$/ )
        Component.onCompleted: setExcludes()
        onActiveFocusChanged: {
            if (!activeFocus && repeater.model.count > 0) {
                updateProxyConfig()
            }
        }

        //: Keep short, placeholder label that cannot wrap
        //% "E.g. example.com, domain.com"
        placeholderText: qsTrId("settings_network-la-exclude_domains_example")

        //% "Exclude domains"
        label: qsTrId("settings_network-la-exclude_domains")

        //% "List valid domain names separated by commas"
        description: errorHighlight ? qsTrId("settings_network_la-exclude_domains_error") : ""

        EnterKey.iconSource: "image://theme/icon-m-enter-close"
        EnterKey.onClicked: parent.focus = true
    }
}
