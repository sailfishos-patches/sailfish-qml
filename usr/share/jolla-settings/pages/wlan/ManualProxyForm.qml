import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Settings.Networking 1.0

Column {
    id: form

    property QtObject network

    property bool updating
    property bool _completed
    property bool _updateRequired

    Connections {
        target: network
        onProxyConfigChanged: {
            if (proxyServersChanged()) {
                setServersModel()
            }
            if (proxyExcludesChanged()) {
                setExcludes()
            }

            timer.restart()
        }
    }

    Timer {
        id: timer

        interval: 1
        onTriggered: {
            form.updating = false
            if (form._updateRequired)
                updateManualProxy()
        }
    }

    function remove(index) {
        var item = repeater.itemAt(index)
        if (item) {
            repeater.model.remove(index)
            updateManualProxy()
        }
    }

    function updateManualProxyIfValid(addressField, portField) {
        if (!_completed)
            return

        if (addressField.validInput && portField.validInput)
            _updateRequired = true

        if (!updating && _updateRequired)
            updateManualProxy()
    }

    function updateManualProxyExcludesIfValid(addressField) {
        if (!_completed)
            return

        if (addressField.validInput)
            _updateRequired = true

        if (!updating && _updateRequired)
            updateManualProxy()
    }

    function updateManualProxy() {
        var proxyServer
        var proxyExcludes
        var proxyConfig = network.proxyConfig

        proxyConfig["Method"] = "manual"
        proxyConfig["Servers"] = []

        var addProxy = function(addressField, portField) {
            if (addressField.validInput && portField.validInput) {
                if (addressField.validProtocol) {
                    proxyServer = addressField.text
                } else {
                    proxyServer = "http://" + addressField.text
                }

                proxyServer = proxyServer + ":" + parseInt(portField.text, 10)
                proxyConfig["Servers"].push(proxyServer)
            }
        }

        for (var i = 0; i < repeater.count; i++) {
            var item = repeater.itemAt(i)
            addProxy(item.addressField, item.portField)
        }

        if (proxyExcludesField.validInput) {
            proxyConfig["Excludes"] = proxyExcludesField.text.replace(" ", "").split(",")
        } else {
            proxyConfig["Excludes"] = []
        }

        if (proxyConfig["Servers"].length > 0) {
            updating = true
            _updateRequired = false
            network.proxyConfig = proxyConfig
        }
    }

    function proxyServersChanged() {
        var changed = false;
        var servers = network.proxyConfig["Servers"]

        if (!servers) {
            if (repeater.model.count !== 0) {
                changed = true
            }
        } else if (servers.length !== repeater.model.count) {
            changed = true
        } else {
            for (var i = 0; i < servers.length; i++) {
                var item = repeater.itemAt(i)
                var serverConfig = servers[i].split(":")
                var address = serverConfig[0] + ":" + serverConfig[1]
                var port = serverConfig[2]

                if (item.addressField.text !== address) {
                    changed = true
                }

                if (item.portField.text !== port) {
                    changed = true
                }
            }
        }
        return changed
    }

    function setServersModel() {
            var servers = network.proxyConfig["Servers"]
            repeater.model.clear()

            if (!servers) {
                repeater.model.append({})
            } else {
                for (var i = 0; i < servers.length; i++) {
                    repeater.model.append({})
                    var item = repeater.itemAt(i)
                    var serverConfig = servers[i].split(":")

                    item.addressField.text = serverConfig[0] + ":" + serverConfig[1]
                    if (serverConfig.length > 2) {
                        item.portField.text = serverConfig[2]
                    }
                }
            }
    }

    Component.onCompleted: _completed = true

    Repeater {
        id: repeater
        model: ListModel {}

        Component.onCompleted: {
            setServersModel()
        }

        ListItem {
            id: proxyItem

            property bool initialized: model.index === 0
            property alias addressField: addressField
            property alias portField: portField

            width: parent.width
            openMenuOnPressAndHold: false
            contentHeight: initialized ? column.height : 0
            opacity: initialized ? 1.0 : 0.0
            _backgroundColor: "transparent"
            Behavior on opacity { FadeAnimation {}}
            Behavior on contentHeight { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }}

            Component.onCompleted: initialized = true
            ListView.onRemove: animateRemoval()

            menu: ContextMenu {
                MenuItem {
                    onClicked: remove(index)
                    //% "Delete"
                    text: qsTrId("settings_network-me-delete")
                }
            }

            Column {
                id: column

                width: parent.width

                SectionHeader {
                    visible: model.index > 0
                    //% "Proxy %1"
                    text: qsTrId("settings_network-he-proxy_number").arg(model.index + 1)
                }

                NetworkAddressField {
                    id: addressField

                    _suppressPressAndHoldOnText: true
                    focusOutBehavior: FocusBehavior.KeepFocus
                    focusOnClick: false
                    onClicked: forceActiveFocus()
                    onPressAndHold: if (repeater.model.count > 1) openMenu()
                    focus: model.index === 0
                    highlighted: activeFocus || menuOpen
                    onActiveFocusChanged: if (!activeFocus) updateManualProxyIfValid(addressField, portField)

                    //: Keep short, placeholder label that cannot wrap
                    //% "E.g. http://proxy.example.com"
                    placeholderText: qsTrId("settings_network-la-manual_proxy_address_example")

                    //% "Proxy address"
                    label: qsTrId("settings_network-la-proxy_address")

                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: portField.focus = true
                }

                IpPortField {
                    id: portField

                    _suppressPressAndHoldOnText: true
                    focusOutBehavior: FocusBehavior.KeepFocus
                    focusOnClick: false
                    onClicked: forceActiveFocus()
                    onPressAndHold: if (repeater.model.count > 1) proxyItem.openMenu()
                    highlighted: activeFocus || menuOpen
                    onActiveFocusChanged: if (!activeFocus) updateManualProxyIfValid(addressField, portField)

                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: {
                        if (model.index + 1 < repeater.count) {
                            repeater.itemAt(model.index + 1).addressField.focus = true
                        } else {
                            proxyExcludesField.focus = true
                        }
                    }
                }
            }
        }
    }

    function proxyExcludesChanged() {
        var changed = false;
        var excludes = WlanUtils.maybeJoin(network.proxyConfig["Excludes"]);

        if (excludes !== proxyExcludesField.text) {
            changed = true
        }

        return changed
    }

    function setExcludes() {
        proxyExcludesField.text = WlanUtils.maybeJoin(network.proxyConfig["Excludes"])
    }


    NetworkField {
        id: proxyExcludesField

        regExp: new RegExp( /^[\w- \.,]*$/ )
        Component.onCompleted: setExcludes()
        onActiveFocusChanged: if (!activeFocus) updateManualProxyExcludesIfValid(proxyExcludesField)

        //: Keep short, placeholder label that cannot wrap
        //% "E.g. example.com, domain.com"
        placeholderText: qsTrId("settings_network-la-exclude_domains_example")

        //% "Exclude domains"
        label: qsTrId("settings_network-la-exclude_domains")

        EnterKey.iconSource: "image://theme/icon-m-enter-close"
        EnterKey.onClicked: parent.focus = true
    }

    BackgroundItem {
        id: addProxyItem

        onClicked: repeater.model.append({})
        Image {
            id: addIcon
            x: Theme.paddingLarge
            anchors.verticalCenter: parent.verticalCenter
            source: "image://theme/icon-m-add" + (addProxyItem.highlighted ? "?" + Theme.highlightColor : "")
        }
        Label {
            id: serviceName

            //% "Add another proxy"
            text: qsTrId("settings_network-bt-add_another_proxy")
            anchors {
                left: addIcon.right
                leftMargin: Theme.paddingSmall
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: Theme.paddingLarge
            }
            color: addProxyItem.highlighted ? Theme.highlightColor : Theme.primaryColor
        }
    }
}
