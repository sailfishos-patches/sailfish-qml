import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Settings.Networking 1.0

Column {
    id: form

    property QtObject network

    property bool _completed
    property bool _updating
    property bool _ipv4UpdateRequired
    property bool _nameserversUpdateRequired
    property bool _domainsUpdateRequired

    Connections {
        target: network
        onIpv4ConfigChanged: timer.restart()
        onNameserversConfigChanged: timer.restart()
        onDomainsConfigChanged: timer.restart()
    }

    Timer {
        id: timer

        interval: 1
        onTriggered: {
            form._updating = false
            if (form._ipv4UpdateRequired)
                updateIPv4()
            else if (form._nameserversUpdateRequired)
                updateDNS()
            else if (form._domainsUpdateRequired)
                updateDomains()
        }
    }

    function checkIp(str) {
        var numbers = str.split(".")

        if (numbers.length !== 4)
            return false

        for (var i = 0; i < numbers.length; i++) {
            if (parseInt(numbers[i], 10) > 255) {
                return false
            }
        }
        return true
    }

    function updateIPv4IfValid(field) {
        if (!_completed)
            return

        if (field.validInput && checkIp(field.text))
            _ipv4UpdateRequired = true

        if (!_updating && _ipv4UpdateRequired)
            updateIPv4()
    }

    function updateIPv4() {
        var config = {"Method": "manual"}
        var isOk = true

        var updateConfig = function(field, key) {
            if (field.validInput && checkIp(field.text)) {
                config[key] = field.text
            } else {
                isOk = false
            }
        }

        updateConfig(addressField, "Address")
        updateConfig(netmaskField, "Netmask")
        updateConfig(gatewayField, "Gateway")

        if (isOk) {
            _updating = true
            _ipv4UpdateRequired = false
            network.ipv4Config = config
        }
    }

    function updateNameserversIfValid(dnsField) {
        if (!_completed)
            return

        if (dnsField.validInput)
            _nameserversUpdateRequired = true

        if (!_updating && _nameserversUpdateRequired)
            updateDNS()
    }

    function updateDNS() {
        var dnslist = []
        var updateList = function(dnsField) {
            var text = dnsField.text

            if (dnsField.validInput) {
                dnslist.push(text)
            }
        }

        updateList(primaryDnsField)
        updateList(secondaryDnsField)

        _updating = true
        _nameserversUpdateRequired = false
        network.nameserversConfig = dnslist
    }

    function updateDomainsIfValid(domainsField) {
        if (!_completed)
            return

        if (domainsField.validInput)
            _domainsUpdateRequired = true

        if (!_updating && _domainsUpdateRequired)
            updateDomains()
    }

    function updateDomains() {
        _updating = true
        _domainsUpdateRequired = false

        if (domainsField.validInput) {
            network.domainsConfig = domainsField.text.replace(" ", "").split(",")
        } else {
            network.domainsConfig = []
        }
    }

    Component.onCompleted: _completed = true

    IPv4AddressField {
        id: addressField

        focus: true

        text: network ? (network.ipv4Config["Address"] || network.ipv4["Address"] || "") : ""
        onActiveFocusChanged: if (!activeFocus) updateIPv4IfValid(addressField)

        //% "E.g. 192.168.1.10"
        placeholderText: qsTrId("settings_network-ph-ip_address_example")
        //% "IP address"
        label: qsTrId("settings_network-la-ip_address")

        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: netmaskField.focus = true
    }

    IPv4AddressField {
        id: netmaskField

        text: network ? (network.ipv4Config["Netmask"] || network.ipv4["Netmask"] || "") : ""
        onActiveFocusChanged: if (!activeFocus) updateIPv4IfValid(netmaskField)

        //% "E.g. 255.255.255.0"
        placeholderText: qsTrId("settings_network-ph-subnet_mask_example")

        //% "Subnet mask"
        label: qsTrId("settings_network-la-subnet_mask")

        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: gatewayField.focus = true
    }

    IPv4AddressField {
        id: gatewayField

        text: network ? (network.ipv4Config["Gateway"] || network.ipv4["Gateway"] || "") : ""
        onActiveFocusChanged: if (!activeFocus) updateIPv4IfValid(gatewayField)

        //% "E.g. 192.168.1.1"
        placeholderText: qsTrId("settings_network-la-default_gateway_example")

        //% "Gateway"
        label: qsTrId("settings_network-la-gateway")

        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: primaryDnsField.focus = true
    }

    IPv4AddressField {
        id: primaryDnsField

        emptyInputOk: true
        Component.onCompleted: text = network.nameserversConfig[0] || network.nameservers[0] || ""
        onActiveFocusChanged: if (!activeFocus) updateNameserversIfValid(primaryDnsField)

        //% "E.g. 1.2.3.4"
        placeholderText: qsTrId("settings_network-la-primary_dns_address_example")

        //% "Primary DNS server"
        label: qsTrId("settings_network-la-primary_dns_server")

        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: secondaryDnsField.focus = true
    }

    IPv4AddressField {
        id: secondaryDnsField

        emptyInputOk: true
        Component.onCompleted: text = network.nameserversConfig[1] || network.nameservers[1] || ""
        onActiveFocusChanged: if (!activeFocus) updateNameserversIfValid(secondaryDnsField)

        //% "E.g. 5.6.7.8"
        placeholderText: qsTrId("settings_network-la-secondary_dns_address_example")

        //% "Secondary DNS server"
        label: qsTrId("settings_network-la-secondary_dns_server")

        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: domainsField.focus = true
    }

    NetworkField {
        id: domainsField

        width: parent.width

        //: Keep short, placeholder label that cannot wrap
        //% "E.g. example.com, domain.com"
        placeholderText: qsTrId("settings_network-ph-default_domain_names_example")

        //% "Default domain names"
        label: qsTrId("settings_network-la-default_domain_names")
        regExp: new RegExp(/^[\w- \.,]*$/)

        Component.onCompleted: text = WlanUtils.maybeJoin(network.domainsConfig) || WlanUtils.maybeJoin(network.domains)
        onActiveFocusChanged: if (!activeFocus) updateDomainsIfValid(domainsField)
        EnterKey.iconSource: "image://theme/icon-m-enter-close"
        EnterKey.onClicked: parent.focus = true
    }
}
