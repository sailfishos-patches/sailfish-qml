import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Settings.Networking 1.0

ListItem {
    id: root

    property bool connected: networkService.state === "online" || (ready && connectCompletionTimer.running)
    property bool ready: networkService.state === "ready"
    property string previousState
    property string currentState: networkService.state

    function getText(state) {
        if (!root.enabled) {
            return ""
        } else if (connected) {
            //% "Connected"
            return qsTrId("settings_network-la-connected_state")
        } else if (state === "ready") {
            //% "Limited connectivity"
            return qsTrId("settings_network-la-limited_state")
        } else if (previousState === "online" && state === "association") {
            // need previous state as well
            // as connman signals 'association' on disconnect as well
            //% "Disconnecting..."
            return qsTrId("settings_network-la-disconnecting_state")
        } else if (state === "association" || state === "configuration") {
            //% "Connecting..."
            return qsTrId("settings_network-la-connecting_state")
        } else {
            //: Open here refers to network without authentication
            //% "Open"
            QT_TRID_NOOP("settings_network-la-open_network")
            //% "Secure"
            QT_TRID_NOOP("settings_network-la-secure_network")

            var security = networkService.security

            if (networkService.name) {
                return security[0] === "none" ? qsTrId("settings_network-la-open_network")
                                              : qsTrId("settings_network-la-secure_network")
            }

            if (security.indexOf("none") >= 0) {
                return qsTrId("settings_network-la-open_network")
            } else if (security.indexOf("wep") >= 0) {
                //% "Secure (WEP)"
                return qsTrId("settings_network-la-secure_wep")
            } else if (security.indexOf("psk") >= 0) {
                //% "Secure (WPA)"
                return qsTrId("settings_network-la-secure_wpa")
            } else {
                return qsTrId("settings_network-la-secure_network")
            }
        }
    }

    enabled: !managed
    contentHeight: textSwitch.height
    highlighted: textSwitch.down || menuOpen || connected || ready
    visible: networkService.type === "wifi"
    _backgroundColor: "transparent"
    openMenuOnPressAndHold: false
    menu: Component {
        ContextMenu {
            MenuItem {
                //% "Connect"
                text: qsTrId("settings_network-me-connect")
                visible: !networkService.connected && networkService.available
                onClicked: networkService.requestConnect()
            }
            MenuItem {
                //% "Disconnect"
                text: qsTrId("settings_network-me-disconnect")
                visible: networkService.connected && !networkService.autoConnect
                onClicked: networkService.requestDisconnect()
            }
            MenuItem {
                //% "Forget"
                text: qsTrId("settings_network-me-forget")

                onClicked: {
                    var network = networkService
                    //% "Forgotten"
                    remorseAction(qsTrId("settings_network-la-forgotten"),
                                  function () { network.remove() })
                }
            }
            MenuItem {
                //% "Edit"
                text: qsTrId("settings_network-me-edit")
                onClicked: pageStack.animatorPush("AdvancedSettingsPage.qml", {"network": networkService})
            }
            onActiveChanged: mainPage.suppressScan = active
        }
    }

    onCurrentStateChanged:  {
        if (previousState === "configuration" && currentState === "ready")
            connectCompletionTimer.start()
        else
            connectCompletionTimer.stop()

        textSwitch.description = getText(currentState)
        previousState = currentState
    }

    ListView.onRemove: animateRemoval()
    Component.onCompleted: textSwitch.description = getText(currentState)

    IconTextSwitch {
        id: textSwitch

        enabled: root.enabled
        icon.source: "image://theme/icon-m-wlan-" + WlanUtils.getStrengthString(networkService.strength)
        automaticCheck: false
        checked: networkService.autoConnect
        highlighted: root.highlighted
        text: networkService.name ? networkService.name
                              //% "Hidden network"
                             : qsTrId("settings_network-la-hidden_network")
        onClicked: networkService.autoConnect = !networkService.autoConnect
        onPressAndHold: root.openMenu()
    }

    Timer {
        id: connectCompletionTimer

        interval: 12000
        repeat: false
        onTriggered: textSwitch.description = getText(currentState)
    }
}
