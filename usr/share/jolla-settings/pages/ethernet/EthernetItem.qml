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
            return qsTrId("settings_network-la-ethernet-connected_state")
        } else if (state === "ready") {
            //% "Limited connectivity"
            return qsTrId("settings_network-la-ethernet-limited_state")
        } else if (previousState === "online" && state === "association") {
            // need previous state as well
            // as connman signals 'association' on disconnect as well
            //% "Disconnecting..."
            return qsTrId("settings_network-la-ethernet-disconnecting_state")
        } else if (state === "association" || state === "configuration") {
            //% "Connecting..."
            return qsTrId("settings_network-la-ethernet-connecting_state")
        } else {
            //% "Idle state"
            return qsTrId("settings_network-la-ethernet-idle_state")
        }
    }

    enabled: !managed
    contentHeight: textSwitch.height
    highlighted: textSwitch.down || menuOpen || connected || ready
    visible: networkService.type === "ethernet"
    _backgroundColor: "transparent"
    openMenuOnPressAndHold: false
    menu: Component {
        ContextMenu {
            MenuItem {
                //% "Connect"
                text: qsTrId("settings_network-me-ethernet-connect")
                visible: !networkService.connected && networkService.available
                onClicked: networkService.requestConnect()
            }
            MenuItem {
                //% "Disconnect"
                text: qsTrId("settings_network-me-ethernet-disconnect")
                visible: networkService.connected && !networkService.autoConnect
                onClicked: networkService.requestDisconnect()
            }
            // The entry will be re-created by ConnMan as non-saved when cleared
            // TODO: We may need to devise means to remove the others that are
            //       not tied to the particular adapter.
            MenuItem {
                //% "Clear settings"
                text: qsTrId("settings_network-me-ethernet-clear-settings")

                onClicked: {
                    var network = networkService
                    //% "Cleared settings"
                    remorseAction(qsTrId("settings_network-la-ethernet-cleared-settings"),
                                    function () {
                                        network.autoConnect = false;
                                        network.requestDisconnect()
                                        network.remove()
                                    })
                }
            }
            MenuItem {
                //% "Details"
                text: qsTrId("settings_network-me-ethernet-details")
                onClicked: pageStack.animatorPush("NetworkDetailsPage.qml", {"network": networkService})
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
        icon.source: "image://theme/icon-m-lan"
        automaticCheck: false
        checked: networkService.autoConnect
        highlighted: root.highlighted
        text: networkService.name
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
