/****************************************************************************
**
** Copyright (C) 2013-2018 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import Sailfish.Telephony 1.0
import Sailfish.Settings.Networking 1.0
import MeeGo.Connman 0.2
import MeeGo.QOfono 0.2
import Nemo.Connectivity 1.0
import Nemo.DBus 2.0
import com.jolla.lipstick 0.1
import com.jolla.connection 1.0
import Nemo.Notifications 1.0 as SystemNotifications
import org.nemomobile.ofono 1.0
import org.nemomobile.lipstick 0.1
import org.nemomobile.configuration 1.0

import "../connectivity"
import "../systemwindow"
import "../main"

SystemWindow {
    id: connectionDialog

    property bool debug
    property bool userInputOk
    property Item selectedItem
    property alias __silica_applicationwindow_instance: fakeApplicationWindow
    property bool verticalOrientation: Lipstick.compositor.topmostWindowOrientation === Qt.PrimaryOrientation
                                    || Lipstick.compositor.topmostWindowOrientation === Qt.PortraitOrientation
                                    || Lipstick.compositor.topmostWindowOrientation === Qt.InvertedPortraitOrientation
    property real keyboardHeight: transpose ? Qt.inputMethod.keyboardRectangle.width : Qt.inputMethod.keyboardRectangle.height
    property real reservedHeight: Math.max(((Screen.sizeCategory < Screen.Large) ? 0.2 * height
                                                                                 : 0.4 * height),
                                           keyboardHeight) - 1

    property var connectionRequestBlockedForType: null

    property var delayedFields: ({})
    property string delayedServicePath

    objectName: "connectionDialog"
    contentHeight: connections.height

    onVisibleChanged: {
        if (!visible) {
            connections.resetState()
        }
    }

    onHidden: {
        // Enable sending requestConnect signal from connman
        connectionAgent.sendConnectReply("Clear")
        connectionSelector.windowVisible = false
        connectionDialog.selectedItem = null
    }

    function closeDialog(connectionSelected) {
        if (!connectionSelected && selectedService.provisioningEap)
            selectedService.remove()
        selectedService.path = ""
        userInputOk = false
        shouldBeVisible = false
        connectionRequestBlockedForType = null
        holdOffTimer.restart()
        dbusNotifier.emitSignal('connectionSelectorClosed', [connectionSelected])
    }

    function normalizeType(type) {
        return type ? ((type === "wlan") ? "wifi" : type) : ""
    }

    function showBlockedConnectionRequest() {
        if (connectionRequestBlockedForType !== null) connectionRequested(connectionRequestBlockedForType)
    }

    function connectionRequested(preferredType) {
        if (!connectionSelector.windowVisible) {
            if ((Lipstick.compositor.deviceIsLocked || Lipstick.compositor.lockScreenLayer.locked || holdOffTimer.running)
                    && !Desktop.startupWizardRunning) {
                connectionRequestBlockedForType = preferredType
            } else {
                connectionSelector.windowVisible = true
                if (preferredType == "wifi") {
                    var lastConnectionIndex = connections.connectionTypeModel.count - 1
                    var lastConnection = connections.connectionTypeModel.get(lastConnectionIndex)
                    connections.connectionTypeSelected(lastConnectionIndex, lastConnection.type, lastConnection.name)
                }
            }
        } else {
            connectionRequestBlockedForType = null
        }
    }

    onSelectedItemChanged: {
        if (!selectedItem) {
            connections.expanded = false
        }
    }

    // animate height with keyboard, but not on orientation changes
    Behavior on keyboardHeight { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

    Item {
        id: fakeApplicationWindow
        // suppresses warnings by context menu
        property int _dimScreen
    }

    SystemDialogLayout {
        id: dialogLayout

        contentHeight: connections.height

        onDismiss: {
            connectionDialog.closeDialog(false)
        }
    }

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

        property real expandedHeight: (verticalOrientation ? Screen.height : Screen.width) - connectionDialog.reservedHeight
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

        property bool busy: (connectingService || disablingTethering || wifiListModel.scanning || delayedScanRequest.running ||
                             (wifiMode && (wifiListModel.count == 0 && (!_wifiTechnology || !_wifiTechnology.tethering))) ) &&
                            !(invalidCredentials || errorCondition) && (!wifiMode || wifiListModel.powered)

        property bool stateInformation: (!wifiMode && ConnectionManager.offlineMode) ||
                                        (wifiMode && (!wifiListModel.powered ||
                                                      (_wifiTechnology && _wifiTechnology.tethering))) ||
                                        busy || invalidCredentials || errorCondition || cellularErrorText.length > 0
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
        height: (connectionDialog.windowVisible && expanded) ? (showStatus ? listView.headerHeight + statusArea.height
                                       : (addingNetwork ? Math.min(contentHeight, expandedHeight) : expandedHeight))
                         : listView.headerHeight
        contentHeight: addingNetwork ? addNetworkView.height : listView.height

        clip: true
        pressDelay: 0
        parent: dialogLayout

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
            } else if (!wifiMode && !ConnectionManager.offlineMode) {
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

            if (debug) { console.debug('Connecting:', service.name, selectedService.autoConnect, '\n') }
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
            var path = ConnectionManager.createServiceSync(formData)

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
            ConnectionManager.offlineMode = false
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

            property Timer outOfRangeTimer: Timer {
                interval: 5000
                onTriggered: connections.connectingService = false
            }

            onAvailableChanged: {
                if (available && !waitingPropertiesReady && connections.connectingService) {
                    outOfRangeTimer.stop()
                    connections.connectService(selectedService)
                }
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
                    topPadding: Screen.sizeCategory >= Screen.Large ? 2*Theme.paddingLarge : Theme.paddingLarge
                }

                Row {
                    id: buttonRow

                    property real buttonWidth: Math.min(parent.width / (cellularRepeater.count + repeater.count),
                                                        Theme.itemSizeHuge*1.5)
                    property bool smallIcon: !verticalOrientation && (Screen.sizeCategory < Screen.Large)
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
                                    if (_cellularTechnology && !_cellularTechnology.powered) {
                                        _cellularTechnology.powered = true
                                    }

                                    if (Telephony.multiSimSupported) {
                                        modemManager.defaultDataSim = model.subscriberIdentity
                                    }
                                    connections.clearCellularError()
                                    if (mobileData.roaming && !mobileData.roamingAllowed) {
                                        //% "Cannot use mobile data while roaming"
                                        connections.setCellularError(qsTrId("lipstick-jolla-home-la-no_mobile_data_when_roaming"))
                                    } else if (mobileData.error) {
                                        //% "Cannot connect to network service"
                                        connections.setCellularError(qsTrId("lipstick-jolla-home-la-network_service_error"))
                                    } else {
                                        connectionDialog.selectedItem = cellularButton
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
                                if (model.type === 'wifi' && !wifiListModel.powered) {
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
                        x: Theme.paddingLarge
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
                        id: item

                        width: header.width
                        anchors.horizontalCenter: parent.horizontalCenter
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
                                    if (!eap)
                                        connections.userInputResponse({})
                                    connections.resetState()
                                }

                                onCloseDialog: connectionDialog.closeDialog(false)

                                onSend: {
                                    if (eap) {
                                        if (!formData['Name'])
                                            formData['Name'] = selectedService.name;
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
                        topMargin: verticalOrientation ? 2*Theme.paddingLarge : Theme.paddingLarge
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
                        } else if (connections.wifiMode && ConnectionManager.offlineMode && !wifiListModel.powered) {
                            //% "Hey, flight mode is on"
                            return qsTrId("lipstick-jolla-home-la-wlan_flight_mode")
                        } else if (connections.wifiMode && !ConnectionManager.offlineMode && !wifiListModel.powered) {
                            //% "Hey, WLAN is disabled"
                            return qsTrId("lipstick-jolla-home-la-wlan_disabled")
                        } else if (connections.wifiMode && _wifiTechnology && _wifiTechnology.tethering) {
                            //% "Sorry, cannot use WLAN during Internet sharing"
                            return qsTrId("lipstick-jolla-home-la-wlan_internet_sharing")
                        } else if (!connections.wifiMode && ConnectionManager.offlineMode) {
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

                    size: verticalOrientation || Screen.sizeCategory >= Screen.Large ? BusyIndicatorSize.Large
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
                    }

                    visible: text != '' && !connections.mobileDataOnly
                    text: {
                        if (connections.invalidCredentials) {
                            //% "Enter new password"
                            return qsTrId("lipstick-jolla-home-bt-enter_new_password")
                        } else if (connections.wifiMode && _wifiTechnology && _wifiTechnology.tethering) {
                            //% "Turn off Internet sharing"
                            return qsTrId("lipstick-jolla-home-bt-disable_internet_sharing")
                        } else if (connections.wifiMode && connections.errorCondition) {
                            //% "Search again"
                            return qsTrId("lipstick-jolla-home-bt-search_again")
                        } else if (connections.wifiMode && !ConnectionManager.offlineMode && !wifiListModel.powered) {
                            //% "Enable WLAN"
                            return qsTrId("lipstick-jolla-home-bt-enable_wlan")
                        } else if (!connections.wifiMode && ConnectionManager.offlineMode) {
                            //% "Disable flight mode"
                            return qsTrId("lipstick-jolla-home-bt-disable_flight_mode")
                        } else if (connections.wifiMode && ConnectionManager.offlineMode && !wifiListModel.powered) {
                            //: Button for disabling flight mode with wlan selected
                            //% "Disable it"
                            return qsTrId("lipstick-jolla-home-bt-disable_it")
                        }

                        return ''
                    }
                    onClicked: {
                        if (connections.invalidCredentials) {
                            connections.retryPassword()
                        } else if (connections.wifiMode && _wifiTechnology && _wifiTechnology.tethering) {
                            connections.disablingTethering = true
                            connectionAgent.stopTethering()
                        } else if (connections.wifiMode && connections.errorCondition) {
                            connections.searchAgain()
                        } else if (connections.wifiMode && !ConnectionManager.offlineMode && !wifiListModel.powered) {
                            wifiListModel.powered = true
                        } else if (!connections.wifiMode && ConnectionManager.offlineMode) {
                            connections.disableFlightMode()
                        } else if (connections.wifiMode && ConnectionManager.offlineMode && !wifiListModel.powered) {
                            connections.disableFlightMode()
                        }
                    }

                    states: [
                        State {
                            when: secondaryButton.visible
                            AnchorChanges {
                                target: primaryButton
                                anchors {
                                    right: parent.horizontalCenter
                                    horizontalCenter: undefined
                                }
                            }
                        },
                        State {
                            when: !secondaryButton.visible
                            AnchorChanges {
                                target: primaryButton
                                anchors {
                                    right: undefined
                                    horizontalCenter: parent.horizontalCenter
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
                    visible: connections.wifiMode && ConnectionManager.offlineMode && !wifiListModel.powered && !connections.mobileDataOnly
                    onClicked: wifiListModel.powered = true
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
        previewSummary: qsTrId("lipstick-jolla-home-la-network_conn_error")
        icon: "icon-system-connection-wlan"
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
        previewSummary: qsTrId("lipstick-jolla-home-la-connection_incorrect_wlan_password")
        previewBody: _networkName.length > 0
                       //: %1 = name of WLAN access point for which the user needs to update the password in order to connect
                       //% "Password change required for '%1'"
                     ? qsTrId("lipstick-jolla-home-la-connection_password_change_required_for").arg(_networkName)
                       //% "Password change required"
                     : qsTrId("lipstick-jolla-home-la-connection_password_change_required")
        summary: previewSummary
        body: previewBody
        icon: "icon-system-connection-wlan"
        urgency: SystemNotifications.Notification.Critical
        //% "Warnings"
        appName: qsTrId("lipstick_jolla_notification-warnings_group")

        remoteActions: [ {
            "name": "default",
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
        changesInhibited: networkList.contextMenuOpen || !connectionSelector.windowVisible
        onPoweredChanged: {
            if (powered)
                delayedScanRequest.start()
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

    ConnectionAgent {
        id: connectionAgent

        property string currentConnectedState

        onConnectionRequest: connectionDialog.connectionRequested()

        onErrorReported: {
            if (debug) { console.debug("  ---- errorReported:", error, "service path:", servicePath, '\n') }

            if (error === "invalid-key") {
                connections.invalidKeyReported = true

                if (!connectionSelector.windowVisible) {
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
                if (!connectionSelector.windowVisible) {
                    connectErrorNotification.testPublish(servicePath)
                }
            }

            if (connectionSelector.windowVisible) {
                // No service is selected, user will get a notification but just ignore it here.
                if (!selectedService.path)
                    return

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
                        console.log("==================== Connection Selector has seen an error:", error)
                    }
                    minimumBusyTimeout.error = true
                }
            }
        }

        onConnectionState: {
            if (debug) { console.debug("  ---- connectionState:", type, state, '\n') }
            currentConnectedState = state

            if (connections.connectingService && (currentConnectedState == "online" || currentConnectedState == "ready")) {
                connectionDialog.closeDialog(true)
            }
        }

        onBrowserRequested: {
            if (url.length === 0)
                url = homePage.value

            captivePortalUrl.load(url)
        }

        onTetheringFinished: {
            delayedScanRequest.start()
            connections.disablingTethering = false
        }

        onUserInputRequested: {
            if (servicePath.indexOf("wifi") > 0) {
                if (!connectionDialog.userInputOk && !connectionDialog.shouldBeVisible) {
                    delayedFields = fields
                    delayedServicePath = servicePath
                    connectionRequested("wifi")
                } else if (connectionDialog.userInputOk) {
                    connections.connectingService = false
                    connections.userInput(servicePath, fields)
                }
            }
            connectionDialog.userInputOk = false
        }
    }

    ConfigurationValue {
        id: homePage
        key: "/apps/sailfish-browser/settings/home_page"
        defaultValue: "http://jolla.com"
    }

    NetworkTechnology {
        id: _wifiTechnology
        path: ConnectionManager.wifiPath
    }

    NetworkTechnology {
        id: _cellularTechnology
        path: ConnectionManager.cellularPath
    }

    Connections {
        target: ConnectionManager
        onConnectionStateChanged: {
            if (ConnectionManager.connectionState == "online") {
                if (ConnectionManager.defaultRoute
                        && ConnectionManager.defaultRoute.path == passwordErrorNotification.lastPublishedNetworkPath) {
                    // Remove notification reporting incorrect password
                    passwordErrorNotification.close()
                }
            }
            passwordErrorNotification.resetService()
            connectErrorNotification.resetService()
        }
    }

    OfonoModem {
        id: modem
        modemPath: simManager.activeModem
    }

    OfonoModemManager {
        id: modemManager
    }

    Connections {
        target: connectionSelector
        onWindowVisibleChanged: {
            if (connectionSelector.windowVisible) {
                connectionDialog.shouldBeVisible = true
            }
        }
    }

    Connections {
        target: Lipstick.compositor
        onDeviceIsLockedChanged: showBlockedConnectionRequest()
        onScreenIsLockedChanged: showBlockedConnectionRequest()
        onDisplayOff: if (connectionSelector.windowVisible) connectionDialog.closeDialog(false)
    }

    DBusInterface {
        id: captivePortalUrl

        property int tabId: -1

        service: "org.sailfishos.browser.ui"
        path: "/ui"
        iface: "org.sailfishos.browser.ui"

        function load(url) {
            call("requestTab", [tabId, url], function(tabId) {
                captivePortalUrl.tabId = tabId
            }, function(error, message) {
                console.warn("Failed to open captive portal url:", url, "error:", error, "message:", message)
            })
        }
    }


    DBusAdaptor {
        id: dbusNotifier

        service: "com.jolla.lipstick.ConnectionSelector"
        path: "/"
        iface: "com.jolla.lipstick.ConnectionSelectorIf"
        xml: "\t<interface name=\"com.jolla.lipstick.ConnectionSelectorIf\">\n" +
             "\t\t<method name=\"openConnection\">\n" +
             "\t\t\t<arg name=\"type\" type=\"s\" direction=\"in\"/>\n" +
             "\t\t</method>\n" +
             "\t\t<method name=\"openConnectionNow\">\n" +
             "\t\t\t<arg name=\"type\" type=\"s\" direction=\"in\"/>\n" +
             "\t\t</method>\n" +
             "\t\t<signal name=\"connectionSelectorClosed\">\n" +
             "\t\t\t<arg name=\"connectionSelected\" type=\"b\" direction=\"out\"/>\n" +
             "\t\t</signal>\n" +
             "\t</interface>\n"

        function openConnection(preferredType) {
            connections.mobileDataOnly = (preferredType === "cellular")
            if (connections.mobileDataOnly) {
                connections.wifiMode = false
                connections.expanded = false

                // Do not show empty dialog
                if (cellularRepeater.count == 0) {
                    console.log("Connection Selector no sim cards present and/or all are disabled.")
                    connections.resetState()
                    return
                }
            }

            // Make sure that top menu layer is closed when requesting connection selector.
            // Top menu will appear above the connection selector.
            Lipstick.compositor.topMenuLayer.hide()
            connectionDialog.connectionRequested(normalizeType(preferredType))
        }

        // For WLAN settings page, pops up immediately
        function openConnectionNow(preferredType) {
            holdOffTimer.stop()
            openConnection(preferredType)
        }

        function updatePassphraseForService(servicePath) {
            if (servicePath.length === 0) {
                console.log("updatePassphraseForService(): no service path")
                return
            }

            if (servicePath.indexOf("wifi") < 0) {
                console.log("updatePassphraseForService() only supports wifi services")
                return
            }

            openConnectionNow('wifi')
            var networkService = wifiListModel.get(wifiListModel.indexOf(servicePath))
            if (networkService) {
                networkService.remove()
                if (connections.userInput(servicePath, null)) {
                    networkList.currentItem.clicked(null)
                }
            } else {
                console.log("updatePassphraseForService(): cannot find network service:", servicePath)
            }
        }
    }

    Timer {
        id: holdOffTimer
        interval: 10000
        onTriggered: showBlockedConnectionRequest()
    }

    SimManager {
        id: simManager

        controlType: SimManagerType.Data
    }
}
