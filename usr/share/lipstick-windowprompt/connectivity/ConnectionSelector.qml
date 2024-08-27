/****************************************************************************
**
** Copyright (C) 2013 - 2022 Jolla Ltd.
** Copyright (C) 2020 Open Mobile Platform LLC.
**
****************************************************************************/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import Sailfish.Telephony 1.0
import Sailfish.Settings.Networking 1.0
import Sailfish.Homescreen.UserAgent 1.0
import Connman 0.2
import QOfono 0.2
import Nemo.Connectivity 1.0
import Nemo.DBus 2.0
import Nemo.Notifications 1.0 as SystemNotifications
import org.nemomobile.ofono 1.0
import Nemo.Configuration 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Policy 1.0

SystemDialog {
    id: connectionDialog

    property bool debug
    property bool userInputOk
    property Item selectedItem

    readonly property bool transpose: orientation === Orientation.Landscape
                || orientation === Orientation.LandscapeInverted
    property real keyboardHeight: transpose ? Qt.inputMethod.keyboardRectangle.width : Qt.inputMethod.keyboardRectangle.height
    readonly property real reservedHeight: Math.max(
                (Screen.sizeCategory < Screen.Large ? 0.2 : 0.4)  * screenHeight, keyboardHeight) - 1
    property int horizontalMargin: Math.max(Theme.paddingLarge,
                                            (transpose && Screen.topCutout.height > 0)
                                            ? Screen.topCutout.height + Theme.paddingSmall : 0)

    property var delayedFields: ({})
    property string delayedServicePath

    objectName: "connectionDialog"
    contentHeight: connections.height

    onVisibleChanged: {
        if (!visible) {
            connections.resetState()
        }
    }

    onClosed: {
        // Enable sending requestConnect signal from connman
        connectionDialog.selectedItem = null
        connectionAgent.closed(false)
    }

    function validWepPassphrase(passphrase) {
        return ((passphrase.length === 5
                 || passphrase.length === 13)
                && passphrase.match(/^[\x00-\x7f]+$/))
                || ((passphrase.length === 10
                     || passphrase.length === 26)
                    && passphrase.match(/^[0-9a-f]+$/i))
    }

    function validPskPassphrase(passphrase) {
        return passphrase && passphrase.length >= 8
                && ((passphrase.length <= 64
                     && passphrase.match(/^[0-9a-f]+$/i))
                    || (passphrase.length <= 63
                        && passphrase.match(/^[\x00-\x7f]+$/)))
    }

    function closeDialog(connectionSelected) {
        if (!connectionSelected && selectedService.provisioningEap)
            selectedService.remove()
        selectedService.path = ""
        userInputOk = false
        connectionAgent.closed(connectionSelected)
        dismiss()
    }

    function showBlockedConnectionRequest() {
        if (connectionRequestBlockedForType !== null) connectionRequested(connectionRequestBlockedForType)
    }

    function connectionRequested(preferredType) {
        activate()
        if (preferredType == "wifi") {
            var lastConnectionIndex = connections.connectionTypeModel.count - 1
            var lastConnection = connections.connectionTypeModel.get(lastConnectionIndex)
            connections.connectionTypeSelected(lastConnectionIndex, lastConnection.type, lastConnection.name)
        }
    }

    onSelectedItemChanged: {
        if (!selectedItem) {
            connections.expanded = false
        }
    }

    QtObject {
        id: pageStack

        readonly property bool busy: false
    }

    // animate height with keyboard, but not on orientation changes
    Behavior on keyboardHeight { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

    Timer {
        id: minimumBusyTimeout

        property bool error

        function reset() {
            error = false
            stop()
        }

        interval: 45000

        onRunningChanged: {
            if (running) {
                if (debug) { console.time("minimumBusyTimeout") }
            } else {
                if (debug) { console.timeEnd("minimumBusyTimeout") }
                if (error) {
                    connections.errorCondition = true
                    selectedService.path = ""
                    error = false
                }
            }
        }
    }

    SilicaFlickable {
        id: connections

        property real expandedHeight: (connectionDialog.transpose ? Screen.width : Screen.height) - connectionDialog.reservedHeight
        property real expansionHeight: expanded ? expandedHeight - listView.headerHeight : 0

        property bool wifiMode
        property bool mobileDataOnly
        property bool expanded
        property bool connectingService
        property bool invalidCredentials
        property bool errorCondition
        property bool invalidKeyReported
        property bool disablingTethering
        property string cellularErrorText

        property bool busy: (connectingService || disablingTethering || delayedScanRequest.running
                             || (wifiMode && (wifiListModel.count == 0
                                              && (!_wifiTechnology || !_wifiTechnology.tethering))))
                            && !(invalidCredentials || errorCondition)
                            && (!wifiMode || wifiListModel.powered)

        property bool stateInformation: (!wifiMode && networkManager.offlineMode)
                                        || (wifiMode && (!wifiListModel.powered
                                                         || (_wifiTechnology && _wifiTechnology.tethering)))
                                        || busy || invalidCredentials || errorCondition || cellularErrorText.length > 0
        property bool showStatus: expanded && stateInformation && !networkListWrapper.visible
        property bool showList: expanded && wifiMode && wifiListModel.powered && !stateInformation && !statusArea.visible
        property bool addingNetwork

        property ListModel connectionTypeModel: ListModel {
            Component.onCompleted: {
                //% "WLAN"
                var wifiText = qsTrId("lipstick-jolla-home-la-connection_wlan_network")
                append({ 'name': wifiText, 'type': 'wifi' })
            }
        }

        width: parent.width
        height: (connectionDialog.visible && expanded)
                ? (showStatus ? listView.headerHeight + statusArea.height
                              : (addingNetwork ? Math.min(contentHeight, expandedHeight) : expandedHeight))
                : listView.headerHeight
        contentHeight: addingNetwork ? addNetworkView.height : listView.height

        clip: true
        pressDelay: 0

        function resetState() {
            // Close the context menu prior to resetting rest of the state.
            if (networkList.contextMenuOpen)
                networkList.currentItem.closeMenu()

            addingNetwork = false
            errorCondition = false
            invalidCredentials = false
            connectingService = false
            selectedService.path = ""
            selectedService.waitingAutoConnect = false
            invalidKeyReported = false
            cellularErrorText = ""
            mobileDataOnly = false
            minimumBusyTimeout.reset()
        }

        function connectionTypeSelected(index, type, name) {
            resetState()
            wifiMode = (type === "wifi")
            expanded = true

            if (wifiMode && wifiListModel.powered) {
                wifiListModel.requestScan()
                connectionDialog.userInputOk = true
            } else if (!wifiMode && !networkManager.offlineMode) {
                connectingService = true
                if (debug) { console.debug('Connecting:', name, '\n') }
                // TODO: differentiate between multiple cellular connections
                connectionAgent.connectToType("cellular")
            }
        }

        // Only for WLAN
        function connectService(service) {
            // Service is already connected, just close.
            if (service.connected) {
                closeDialog(true)
                return
            }

            // Already connecting or about to start connecting
            connectingService = true

            // Service is already connecting, wait for it to complete.
            if (service.state !== "idle" && service.state !== "failure") {
                selectedService.path = service.path
                return
            }

            connectionDialog.userInputOk = true

            if (debug) { console.debug('Connecting:', service.name, selectedService.autoConnect, service.path) }
            selectedService.path = service.path
            if (service.securityType === NetworkService.SecurityIEEE802
                && !service.saved) {
                networkList.currentIndex = wifiListModel.indexOf(service.path)
                networkList.currentItem.openMenu({"eap": true, "servicePath": service.path})
                connectingService = false
            } else if (!selectedService.autoConnect) {
                selectedService.waitingAutoConnect = true
                selectedService.requestConnect()
            } else {
                selectedService.requestConnect()
            }
        }

        function userInput(servicePath, fields) {
            var index = wifiListModel.indexOf(servicePath)
            if (index >= 0) {
                networkList.currentIndex = index
                if (networkList.currentItem) {
                    networkList.currentItem.openMenu({"eap": false, "fields": fields || {}, "servicePath": servicePath})
                    return true
                } else {
                    if (debug) { console.debug('Could not give user input focus to item at index:', index, '\n') }
                }
            } else {
                if (debug) { console.debug('Connection error - cannot find service in list:', servicePath, '\n') }
                connectingService = false
                connectionAgent.sendUserReply({})
            }
            return false
        }

        function asciiToHex(x) {
            var result = ""
            if (!x || !x.length) return result
            for (var i = 0; i < x.length; i++) {
                var unicode = x.charCodeAt(i)
                if (unicode <= 127) result += unicode.toString(16)
                else result += encodeURI(x.charAt(i)).replace(/%/g,"")
            }
            return result.toLocaleLowerCase()
        }

        function provision(formData) {
            var path = networkManager.createServiceSync(formData)

            networkSetupLoader.active = true
            networkSetupLoader.item.setup(path)
            connections.resetState()
            if (path.length > 0) {
                selectedService.path = path
                selectedService.waitingPropertiesReady = true
                connections.connectingService = true
            }
        }

        function userInputResponse(formData) {
            networkList.currentItem.closeMenu()
            connectingService = true
            connectionAgent.sendUserReply(formData)
            if (selectedService && selectedService.name === "") {//need to switcheroo for hidden AP
                selectedService.path = selectedService.path.replace(/hidden(?:_[0-9a-f]{12}(?=_))?/, asciiToHex(formData.Name))
            }
        }

        function searchAgain() {
            resetState()
            wifiListModel.requestScan()
        }

        function retryPassword() {
            // Ensure that we are asked for credentials again
            selectedService.remove()
            invalidCredentials = false
            invalidKeyReported = false
            connectService(selectedService)
        }

        function disableFlightMode() {
            networkManager.offlineMode = false
            if (!modem.powered) {
                modem.powered = true
            }
            modem.online = true
        }

        function setCellularError(errorText) {
            cellularErrorText = errorText
            errorCondition = true
        }

        function clearCellularError() {
            cellularErrorText = ""
            errorCondition = false
        }

        NetworkService {
            id: selectedService

            property bool waitingPropertiesReady
            property bool waitingAutoConnect
            property bool provisioningEap
            property bool wasAvailable

            property Timer outOfRangeTimer: Timer {
                interval: 5000
                onTriggered: connections.connectingService = false
            }

            // FIXME: This exists to workaround a shortcoming with libconnman-qt
            // as that sends sometimes extra signals causing onAvailableChanged
            // to fire even if the value was the same as on previous call.
            // JB#57750
            Component.onCompleted: wasAvailable = available

            onAvailableChanged: {
                if (!wasAvailable && available && !waitingPropertiesReady && connections.connectingService) {
                    outOfRangeTimer.stop()
                    connections.connectService(selectedService)
                }
                wasAvailable = available
            }

            onPropertiesReady: {
                if (waitingPropertiesReady) {
                    if (available) {
                        connections.connectService(selectedService)
                    } else if (hidden) {
                        outOfRangeTimer.restart()
                    } else {
                        connections.connectingService = false
                    }

                    waitingPropertiesReady = false
                }
            }

            onConnectedChanged: {
                if (!autoConnect) {
                    autoConnect = true
                }
                connectionDialog.closeDialog(true)
            }

            onPathChanged: {
                provisioningEap = false
                minimumBusyTimeout.reset()
                if (!path) {
                    waitingAutoConnect = false
                    if (connections.invalidCredentials) {
                        // Invalid password was entered
                        connections.invalidCredentials = false
                        connections.errorCondition = true
                    }
                } else if (waitingAutoConnect && !autoConnect) {
                    autoConnect = true
                }
            }

            onAutoConnectChanged: {
                if (autoConnect && waitingAutoConnect) {
                    requestConnect()
                }
            }
        }

        Loader {
            id: addNetworkView

            clip: true
            active: connections.addingNetwork || opacity > 0.0
            width: parent.width
            sourceComponent: AddNetworkView {
                horizontalMargin: connectionDialog.horizontalMargin
                onAccepted: {
                    connections.provision(config)
                    selectedService.provisioningEap = false
                    connections.addingNetwork = false
                }
                onRejected: connections.resetState()
                onCloseDialog: connectionDialog.closeDialog(false)
            }
            Loader {
                id: networkSetupLoader
                sourceComponent: AddNetworkNotifications {}
            }

            enabled: connections.addingNetwork && status === Loader.Ready
            opacity: enabled ? 1.0 : 0.0
            visible: opacity > 0.0
            Behavior on opacity { FadeAnimation {} }
            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
        }

        Column {
            id: listView

            property alias headerHeight: headerColumn.height

            clip: true
            width: parent.width

            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
            enabled: !connections.addingNetwork
            opacity: enabled ? 1.0 : 0.0
            Behavior on opacity { FadeAnimation {} }

            Column {
                id: headerColumn

                width: parent.width

                SystemDialogHeader {
                    id: header
                    //% "Select internet connection"
                    title: qsTrId("lipstick-jolla-home-he-connection_select")
                    tight: true
                }

                Row {
                    id: buttonRow

                    property real buttonWidth: Math.min(parent.width / (cellularRepeater.count + repeater.count),
                                                        Theme.itemSizeHuge*1.5)
                    property bool smallIcon: connectionDialog.transpose && (Screen.sizeCategory < Screen.Large)
                    property int fontSize: (Screen.sizeCategory < Screen.Large) ? Theme.fontSizeExtraSmall
                                                                                 : Theme.fontSizeSmall
                    property int padding: smallIcon ? Theme.paddingSmall
                                                    : (Screen.sizeCategory < Screen.Large) ? Theme.paddingMedium
                                                                                           : Theme.paddingLarge

                    anchors.horizontalCenter: parent.horizontalCenter
                    Repeater {
                        id: cellularRepeater

                        model: OfonoExtSimListModel {}
                        visible: count > 0

                        SystemDialogIconButton {
                            id: cellularButton

                            property string modemPath: model.path

                            height: Math.max(implicitHeight, buttonRow.height)
                            width: buttonRow.buttonWidth
                            text: {
                                if (model.valid && model.serviceProviderName) {
                                    if (model.slot > 0 && Telephony.multiSimSupported) {
                                        return Telephony.shortSimDescription(model.slot) + "\n" + model.serviceProviderName
                                    } else {
                                        return model.serviceProviderName
                                    }
                                }
                                //% "Mobile data %1"
                                return qsTrId("lipstick-jolla-home-la-connection_mobile_data").arg(cellularRepeater.count > 1
                                                                                                  ? index + 1 : "")
                            }

                            font.pixelSize: buttonRow.fontSize
                            iconSource: "image://theme/" + "icon-" + (buttonRow.smallIcon ? "m" : "l")  + "-mobile-network"
                            topPadding: buttonRow.padding
                            bottomPadding: buttonRow.padding
                            contentHighlighted: selectedItem === cellularButton
                            onClicked: {
                                connections.wifiMode = false
                                connections.expanded = true
                                if (!mobileData.offlineMode) {
                                    _cellularTechnology.powered = true
                                    connections.clearCellularError()
                                    if (mobileData.roaming && !mobileData.roamingAllowed) {
                                        //% "Cannot use mobile data while roaming"
                                        connections.setCellularError(qsTrId("lipstick-jolla-home-la-no_mobile_data_when_roaming"))
                                    } else if (mobileData.error) {
                                        //% "Cannot connect to network service"
                                        connections.setCellularError(qsTrId("lipstick-jolla-home-la-network_service_error"))
                                    } else {
                                        connectionDialog.selectedItem = cellularButton
                                        // TODO: This should not be needed / used for mobile data?
                                        selectedService.path = mobileData.identifier
                                        connections.connectingService = true
                                        minimumBusyTimeout.restart()

                                        mobileData.autoConnect = true

                                        // Close immediately if already connected.
                                        // WLAN preferred by the system.
                                        if (mobileData.connected || wifiListModel.connected) {
                                            closeDialog(true)
                                        }
                                    }
                                }
                            }

                            MobileDataConnection {
                                id: mobileData

                                objectName: "ConnectionSelector_MobileDataConnection"

                                modemPath: connectionDialog.visible ? cellularButton.modemPath : ""
                            }
                        }
                    }

                    Repeater {
                        id: repeater

                        model: connections.connectionTypeModel
                        visible: count > 0

                        SystemDialogIconButton {
                            id: button

                            height: Math.max(implicitHeight, buttonRow.height)
                            width: buttonRow.buttonWidth
                            visible: !connections.mobileDataOnly
                            text: model.name
                            font.pixelSize: buttonRow.fontSize
                            iconSource: "image://theme/" + "icon-"  + (buttonRow.smallIcon ? "m" : "l")  + "-wlan"
                            topPadding: buttonRow.padding
                            bottomPadding: buttonRow.padding
                            contentHighlighted: selectedItem === button || (model.type === "wifi" && connections.wifiMode)
                            onClicked: {
                                if (model.type === 'wifi' && !wifiListModel.powered && AccessPolicy.wlanToggleEnabled) {
                                    wifiListModel.powered = true
                                }
                                selectedItem = button
                                connections.connectionTypeSelected(index, model.type, model.name)
                            }
                        }
                    }
                }
            }

            Column {
                id: networkListWrapper

                width: parent.width
                visible: opacity > 0.0
                opacity: connections.showList ? 1.0 : 0.0
                Behavior on opacity { FadeAnimation {} }

                BackgroundItem {
                    id: addNetworkItem

                    onClicked: connections.addingNetwork = true

                    width: header.width
                    anchors.horizontalCenter: parent.horizontalCenter
                    Image {
                        id: addIcon

                        x: connectionDialog.horizontalMargin
                        anchors.verticalCenter: parent.verticalCenter
                        source: "image://theme/icon-m-add" + (addNetworkItem.highlighted ? "?" + Theme.highlightColor : "")
                    }
                    Label {
                        //% "Add network"
                        text: qsTrId("lipstick-jolla-home-bt-add_network")
                        anchors {
                            left: addIcon.right
                            leftMargin: Theme.paddingSmall
                            verticalCenter: parent.verticalCenter
                            right: parent.right
                            rightMargin: Theme.paddingLarge
                        }
                        color: addNetworkItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                    }
                }

                ColumnView {
                    id: networkList

                    property bool contextMenuOpen: currentItem !== null && currentItem.menuOpen

                    width: parent.width
                    itemHeight: Theme.itemSizeSmall

                    // Drop list if we switch connection types
                    model: connections.wifiMode ? wifiListModel : null

                    delegate: WlanItem {
                        width: header.width
                        anchors.horizontalCenter: parent.horizontalCenter
                        horizontalMargin: connectionDialog.horizontalMargin
                        onClicked: {
                            if (selectedService.path !== networkService.path) {
                                connections.resetState()
                                selectedService.path = networkService.path
                                connections.connectService(networkService)
                            }
                        }

                        menu: Component {
                            CredentialsForm {
                                onCancel: {
                                    if (!eap) {
                                        connections.userInputResponse({})
                                    }
                                    connections.resetState()
                                }

                                onCloseDialog: connectionDialog.closeDialog(false)

                                onSend: {
                                    if (eap) {
                                        if (!formData['Name']) {
                                            formData['Name'] = selectedService.name
                                        }
                                        connections.provision(formData)
                                        selectedService.provisioningEap = true
                                    } else {
                                        connections.userInputResponse(formData)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: statusArea
                width: parent.width
                visible: opacity > 0.0
                opacity: connections.showStatus ? 1.0 : 0.0
                Behavior on opacity { FadeAnimation {} }

                // Break binding loops of the statusArea.
                states: [
                    State {
                        when: busyIndicator.running
                        PropertyChanges {
                            target: statusArea
                            height: Math.max(busyIndicator.y + busyIndicator.height + Theme.paddingLarge,
                                             primaryButton.y + primaryButton.height)
                        }
                    },
                    State {
                        when: !busyIndicator.running
                        PropertyChanges {
                            target: statusArea
                            height: primaryButton.y + primaryButton.height
                        }
                    }
                ]

                Label {
                    id: statusLabel
                    anchors {
                        top: statusArea.top
                        topMargin: connectionDialog.transpose ? Theme.paddingLarge : 2 * Theme.paddingLarge
                        left: statusArea.left
                        leftMargin: Theme.paddingLarge
                        right: statusArea.right
                        rightMargin: Theme.paddingLarge
                    }
                    color: Theme.highlightColor
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeMedium
                    wrapMode: Text.Wrap
                    text: {
                        if (connections.cellularErrorText) {
                            return connections.cellularErrorText
                        } else if (connections.invalidCredentials) {
                            //% "Sorry, password is incorrect"
                            return qsTrId("lipstick-jolla-home-la-incorrect_password")
                        } else if (connections.errorCondition) {
                            //% "Sorry, could not connect to selected network"
                            return qsTrId("lipstick-jolla-home-la-connection_error")
                        } else if (connections.wifiMode && networkManager.offlineMode && !wifiListModel.powered) {
                            //% "Hey, flight mode is on"
                            return qsTrId("lipstick-jolla-home-la-wlan_flight_mode")
                        } else if (connections.wifiMode && !networkManager.offlineMode && !wifiListModel.powered) {
                            //% "Hey, WLAN is disabled"
                            return qsTrId("lipstick-jolla-home-la-wlan_disabled")
                        } else if (connections.wifiMode && _wifiTechnology && _wifiTechnology.tethering) {
                            //% "Sorry, cannot use WLAN during Internet sharing"
                            return qsTrId("lipstick-jolla-home-la-wlan_internet_sharing")
                        } else if (!connections.wifiMode && networkManager.offlineMode) {
                            //% "Sorry, cannot use mobile data in flight mode"
                            return qsTrId("lipstick-jolla-home-la-flight_mode")
                        } else if (connections.connectingService) {
                            //% "Connecting"
                            return qsTrId("lipstick-jolla-home-la-connecting")
                        } else if (connections.wifiMode && (wifiListModel.scanning || delayedScanRequest.running || connections.disablingTethering ||
                                   wifiListModel.count == 0)) {
                            //% "Searching"
                            return qsTrId("lipstick-jolla-home-la-searching")
                        }
                        return ''
                    }
                }
                BusyIndicator {
                    id: busyIndicator
                    anchors {
                        top: statusLabel.bottom
                        horizontalCenter: statusArea.horizontalCenter
                        topMargin: Theme.paddingMedium
                    }

                    size: !connectionDialog.transpose || Screen.sizeCategory >= Screen.Large
                            ? BusyIndicatorSize.Large
                            : BusyIndicatorSize.Medium
                    running: connections.busy
                    visible: running
                    opacity: 1.0
                }

                SystemDialogTextButton {
                    id: primaryButton

                    width: secondaryButton.visible ? header.width / 2 : header.width
                    height: secondaryButton.visible ? Math.max(implicitHeight, secondaryButton.implicitHeight)
                                                    : implicitHeight
                    anchors {
                        top: statusLabel.bottom
                        topMargin: Theme.paddingMedium
                        right: secondaryButton.visible ? parent.horizontalCenter : undefined
                        horizontalCenter: secondaryButton.visible ? undefined : parent.horizontalCenter
                    }

                    visible: text != '' && !connections.mobileDataOnly

                    states: [
                        State {
                            when: connections.invalidCredentials
                            PropertyChanges {
                                target: primaryButton
                                //% "Enter new password"
                                text: qsTrId("lipstick-jolla-home-bt-enter_new_password")
                                onClicked: connections.retryPassword()
                            }
                        },
                        State {
                            when: connections.wifiMode && _wifiTechnology && _wifiTechnology.tethering
                            PropertyChanges {
                                target: primaryButton
                                //% "Turn off Internet sharing"
                                text: qsTrId("lipstick-jolla-home-bt-disable_internet_sharing")
                                onClicked: {
                                    connections.disablingTethering = true
                                    connectionAgent.stopTethering("wifi")
                                }
                            }
                        },
                        State {
                            when: connections.wifiMode && connections.errorCondition
                            PropertyChanges {
                                target: primaryButton
                                //% "Search again"
                                text: qsTrId("lipstick-jolla-home-bt-search_again")
                                onClicked: connections.searchAgain()
                            }
                        },
                        State {
                            when: connections.wifiMode && !networkManager.offlineMode && !wifiListModel.powered
                            PropertyChanges {
                                target: primaryButton
                                //% "Enable WLAN"
                                text: qsTrId("lipstick-jolla-home-bt-enable_wlan")
                                opacity: AccessPolicy.wlanToggleEnabled ? 1.0 : Theme.opacityHigh
                                onClicked: {
                                    if (!AccessPolicy.wlanToggleEnabled) {
                                        disableByMdm.publish()
                                        return
                                    }
                                    wifiListModel.powered = true
                                }
                            }
                        },
                        State {
                            when: networkManager.offlineMode && (!connections.wifiMode || (connections.wifiMode && !wifiListModel.powered))
                            PropertyChanges {
                                target: primaryButton
                                //% "Disable flight mode"
                                text: qsTrId("lipstick-jolla-home-bt-disable_flight_mode")
                                opacity: AccessPolicy.flightModeToggleEnabled ? 1.0 : Theme.opacityHigh
                                onClicked: {
                                    if (!AccessPolicy.flightModeToggleEnabled) {
                                        disableByMdm.publish()
                                        return
                                    }
                                    connections.disableFlightMode()
                                }
                            }
                        }
                    ]
                }
                SystemDialogTextButton {
                    id: secondaryButton

                    width: header.width / 2
                    height: primaryButton.height
                    anchors {
                        left: parent.horizontalCenter
                        top: primaryButton.top
                    }

                    //: Button for enabling currently disabled wlan on flight mode
                    //% "WLAN only"
                    text: qsTrId("lipstick-jolla-home-bt-wlan_only")
                    visible: connections.wifiMode && networkManager.offlineMode && !wifiListModel.powered && !connections.mobileDataOnly
                    opacity: AccessPolicy.wlanToggleEnabled ? 1.0 : Theme.opacityHigh
                    onClicked: {
                        if (!AccessPolicy.wlanToggleEnabled) {
                            disableByMdm.publish()
                            return
                        }
                        wifiListModel.powered = true
                    }
                }
            }
        }

        VerticalScrollDecorator {}
    }

    SystemNotifications.Notification {
        id: connectErrorNotification

        property string _networkPath

        function testPublish(networkServicePath) {
            if (networkServicePath != _networkPath) {
                _networkPath = networkServicePath
                publish()
            }
        }

        function resetService() {
            _networkPath = ""
        }

        //% "Network connection error"
        summary: qsTrId("lipstick-jolla-home-la-network_conn_error")
        appIcon: "icon-system-connection-wlan"
        isTransient: true
        urgency: SystemNotifications.Notification.Critical
    }

    SystemNotifications.Notification {
        id: passwordErrorNotification

        property string lastPublishedNetworkPath
        property string _networkPath
        property string _networkName

        function testPublish(networkServicePath, networkServiceName) {
            // Avoid showing the notification for the same service on consecutive attempts
            if (networkServicePath != _networkPath) {
                _networkPath = networkServicePath
                _networkName = networkServiceName
                lastPublishedNetworkPath = networkServicePath
                publish()
            }
        }

        function resetService() {
            _networkPath = ""
            _networkName = ""
        }

        //% "Incorrect WLAN password"
        summary: qsTrId("lipstick-jolla-home-la-connection_incorrect_wlan_password")
        body: _networkName.length > 0
                       //: %1 = name of WLAN access point for which the user needs to update the password in order to connect
                       //% "Password change required for '%1'"
                     ? qsTrId("lipstick-jolla-home-la-connection_password_change_required_for").arg(_networkName)
                       //% "Password change required"
                     : qsTrId("lipstick-jolla-home-la-connection_password_change_required")
        appIcon: "icon-system-connection-wlan"
        urgency: SystemNotifications.Notification.Critical
        //% "Warnings"
        appName: qsTrId("lipstick_jolla_notification-warnings_group")

        remoteActions: [ {
            "name": "default",
            //: Change the WLAN password
            //% "Change"
            "displayName": qsTrId("lipstick-jolla-home-la-connection_change_password"),
            "service": "com.jolla.lipstick.ConnectionSelector",
            "path": "/",
            "iface": "com.jolla.lipstick.ConnectionSelectorIf",
            "method": "updatePassphraseForService",
            "arguments": [ passwordErrorNotification._networkPath ]
        }]
    }

    TechnologyModel {
        id: wifiListModel

        name: "wifi"
        changesInhibited: networkList.contextMenuOpen || !connectionDialog.visible
        onPoweredChanged: {
            if (powered) {
                delayedScanRequest.stop()
                requestScan()
            }
        }
        onScanRequestFinished: {
            if (delayedServicePath.length > 0) {
                connections.userInput(delayedServicePath, delayedFields)
                delayedServicePath = ""
                delayedFields = ({})
            }
        }
    }

    Timer {
        id: delayedScanRequest
        interval: 500
        onTriggered: wifiListModel.requestScan()
    }

    HomescreenConnectionAgent {
        id: connectionAgent

        onClose: connectionDialog.closeDialog(false)

        onConnectionRequest: {
            connections.mobileDataOnly = (preferredType === "cellular")
            if (connections.mobileDataOnly) {
                connections.wifiMode = false
                connections.expanded = false

                // Do not show empty dialog
                if (cellularRepeater.count == 0) {
                    console.warn("Connection Selector no sim cards present and/or all are disabled.")
                    connections.resetState()
                    return
                }
            }
            connectionDialog.connectionRequested(preferredType)
        }

        onErrorReported: {
            if (debug) { console.debug("  ---- errorReported:", error, "service path:", servicePath, '\n') }

            if (error === "invalid-key") {
                connections.invalidKeyReported = true

                if (!connectionDialog.visible) {
                    // Show notification and prompt for passphrase entry
                    var networkService = null
                    if (wifiListModel.count) {
                        networkService = wifiListModel.get(wifiListModel.indexOf(servicePath))
                    }
                    if (networkService) {
                        if (networkService.strength > 0) {  // don't try to connect if network is now offline
                            passwordErrorNotification.testPublish(servicePath, networkService.name)
                        }
                    } else {
                        // ConnectionSelector has not scanned for wifi services, so probably connecting
                        // to a known AP from WLAN settings.
                        passwordErrorNotification.testPublish(servicePath, "")
                    }
                }
            } else if (error === "connect-failed") {
                if (!connectionDialog.visible) {
                    connectErrorNotification.testPublish(servicePath)
                }
            }

            if (connectionDialog.visible) {
                // No service is selected, user will get a notification but just ignore it here.
                if (!selectedService.path) {
                    return
                }

                if (debug) { console.debug('Connect failed - error:', error, '\n') }
                if (networkList.contextMenuOpen) {
                    networkList.currentItem.closeMenu()
                }

                var cellularStayConnecting = selectedService.type == "cellular" && minimumBusyTimeout.running

                if (error === "Passphrase required" || error === "invalid-key" || connections.invalidKeyReported) {
                    connections.invalidCredentials = true
                    connections.errorCondition = false
                } else if (!connections.invalidCredentials && !cellularStayConnecting) {
                    connections.errorCondition = true
                    selectedService.path = ""
                }

                // Stay on the busy state if cellular service lost has lost carrier.
                connections.connectingService = cellularStayConnecting
                if (cellularStayConnecting) {
                    if (debug) {
                        console.debug("==================== Connection Selector has seen an error:", error)
                    }
                    minimumBusyTimeout.error = true
                }
            }
        }

        onConnectionState: {
            if (debug) { console.debug("  ---- connectionState:", type, state, '\n') }

            if (connections.connectingService && (state == "online" || state == "ready")) {
                connectionDialog.closeDialog(true)
            }
        }

        onTetheringFinished: {
            delayedScanRequest.start()
            connections.disablingTethering = false
        }

        onUserInputRequested: {
            if (!connectionDialog.userInputOk) {
                delayedFields = fields
                delayedServicePath = servicePath
            } else {
                connections.connectingService = false
                connections.userInput(servicePath, fields)
            }
            connectionDialog.userInputOk = false
        }

        onUpdatePassphrase: {
            var networkService = wifiListModel.get(wifiListModel.indexOf(servicePath))
            if (networkService) {
                networkService.remove()
                if (connections.userInput(servicePath, null)) {
                    networkList.currentItem.clicked(null)
                }
            } else {
                console.warn("updatePassphraseForService(): cannot find network service:", servicePath)
            }
        }
    }

    NetworkTechnology {
        id: _wifiTechnology
        path: networkManager.WifiTechnology
    }

    NetworkTechnology {
        id: _cellularTechnology
        path: networkManager.CellularTechnology
    }

    NetworkManager {
        id: networkManager
        technologiesEnabled: false

        onStateChanged: {
            if (state == "online"
                    && defaultRoute
                    && defaultRoute.path === passwordErrorNotification.lastPublishedNetworkPath) {
                // Remove notification reporting incorrect password
                passwordErrorNotification.close()
            }
            passwordErrorNotification.resetService()
            connectErrorNotification.resetService()
        }
    }

    OfonoModem {
        id: modem
        modemPath: simManager.activeModem
    }

    SimManager {
        id: simManager

        controlType: SimManagerType.Data
    }

    SystemNotifications.Notification {
        id: disableByMdm
        //% "Disabled by %1 Device Manager"
        summary: qsTrId("lipstick-jolla-home-la-disabled_by_device_manager")
                                                  .arg(aboutSettings.baseOperatingSystemName)

        isTransient: true
        icon: "icon-system-warning"
    }

    AboutSettings {
        id: aboutSettings
    }
}
