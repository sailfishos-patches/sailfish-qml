/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import com.jolla.settings.system 1.0
import Sailfish.Settings.Networking 1.0
import MeeGo.Connman 0.2
import ".."

CsdTestPage {
    id: page

    property int timeout: 30 * 1000
    property int timeoutCountdown

    function _restart() {
        statusModel.clear()
        _restartTimeout()
        mdmBanner.active = wifiTechModel.available && !wifiTechModel.powered
        if (mdmBanner.active) {
            page.state = "done-error"
        } else {
            page.state = "initializing"
            if (wifiTechModel.powered) {
                page.state = "scanning"
            }
        }
    }

    function _restartTimeout() {
        timeoutCountdown = timeout
        timeoutTimer.restart()
    }

    onStatusChanged: {
        if (status == PageStatus.Active && state == "") {
            _restart()
        }
    }

    onStateChanged: {
        console.log("WLAN test state:", state)
    }

    onPageContainerChanged: {
        if (pageContainer == null) {    // page was popped
            wifiTechModel.restoreInitialPoweredState()
        }
    }

    states: [
        State {
            name: "initializing"
            StateChangeScript {
                script: {
                    page._restartTimeout()
                    //% "Turning WLAN on..."
                    var statusText = qsTrId("csd-la-status_power_on_wlan")
                    statusModel.append({"statusText": statusText, "statusColor": "white"})
                }
            }
        },
        State {
            name: "scanning"
            StateChangeScript {
                script: {
                    //% "Searching for access points"
                    var statusText = qsTrId("csd-la-status_searching_for_access_points")
                    statusModel.append({"statusText": statusText, "statusColor": "white"})
                }
            }
        },
        State {
            name: "done-success"
            PropertyChanges { target: timeoutTimer; running: false }
            StateChangeScript {
                script: {
                    //% "Test passed."
                    var statusText = qsTrId("csd-la-wifi_status_pass")
                    statusModel.append({"statusText": statusText, "statusColor": "green"})

                    page.setTestResult(true)
                    testCompleted(false)
                }
            }
        },
        State {
            name: "done-error"
            PropertyChanges { target: restartButton; visible: wifiTechModel.available }
            PropertyChanges { target: exitButton; visible: !page.isContinueTest }
            PropertyChanges { target: timeoutTimer; running: false }
            StateChangeScript {
                script: {
                    page.setTestResult(false)
                    testCompleted(false)
                }
            }
        },
        State {
            name: "done-error-timeout"
            extend: "done-error"
            StateChangeScript {
                script: {
                    //% "Error: test timed out!"
                    var errorStatus = qsTrId("csd-la-status_wifi_timeout")
                    statusModel.append({"statusText": errorStatus, "statusColor": "red"})
                }
            }
        }
    ]

    PolicyValue {
        id: policy
        policyType: PolicyValue.WlanToggleEnabled
    }

    CsdPageHeader {
        id: header
        //% "WLAN"
        title: qsTrId("csd-he-wlan")
    }

    DisabledByMdmBanner {
        id: mdmBanner
        anchors.top: header.bottom
        active: false
        Timer {
            id: disabledByMdmFailTimer
            interval: 2500
            running: true
            onTriggered: {
                if (mdmBanner.active) {
                    setTestResult(false)
                    testCompleted(true)
                }
            }
        }
    }

    Column {
        id: contentColumn
        anchors.top: mdmBanner.active ? mdmBanner.bottom : header.bottom
        anchors.topMargin: mdmBanner.active ? Theme.paddingLarge : 0
        x: Theme.horizontalPageMargin
        width: parent.width - 2*x
        height: parent.height - header.height - (mdmBanner.active ? (mdmBanner.height+Theme.paddingLarge) : 0) - (buttonSet.height + buttonSet.anchors.bottomMargin)
        spacing: Theme.paddingLarge
        clip: true

        Column {
            id: topInfoColumn
            width: parent.width

            Label {
                width: parent.width
                wrapMode: Text.WordWrap
                font.bold: true
                visible: !mdmBanner.active

                //% "Status:"
                text: qsTrId("csd-la-status_wifi")
            }
            Repeater {
                model: ListModel { id: statusModel }
                delegate: Label {
                    width: contentColumn.width
                    wrapMode: Text.WordWrap
                    color: model.statusColor
                    font.bold: true
                    text: model.statusText
                }
            }

            SectionHeader {
                //% "Networks"
                text: qsTrId("csd-la-wifi_networks")
                visible: wifiTechModel.count > 0
            }
        }

        SilicaFlickable {
            id: results
            width: parent.width
            height: parent.height - topInfoColumn.height
            contentHeight: foundNetworks.height
            clip: true

            Column {
                id: foundNetworks
                width: parent.width
                Repeater {
                    model: wifiTechModel
                    delegate: Column {
                        width: parent.width
                        Item {
                            width: parent.width
                            height: wifiName.height

                            Label {
                                id: wifiName
                                anchors {
                                    left: parent.left
                                    right: icon.right
                                }
                                text: networkService.name
                                      ? networkService.name
                                        //% "Hidden network"
                                      : qsTrId("csd-la-hidden_network")
                                color: Theme.highlightColor
                            }

                            Image {
                                id: icon
                                anchors {
                                    right: parent.right
                                }
                                source: "image://theme/icon-m-wlan-" + WlanUtils.getStrengthString(modelData.strength) + "?" + Theme.highlightColor
                            }
                        }

                        Label {
                            text: networkService.frequency + " MHz"
                            color: Theme.secondaryHighlightColor
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Label {
                            text: networkService.strength + " %"
                            color: Theme.secondaryHighlightColor
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Label {
                            text: networkService.security
                            color: Theme.secondaryHighlightColor
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Item {
                            width: parent.width
                            height: Theme.paddingLarge
                        }
                    }
                }
            }
        }
    }

    Column {
        id: buttonSet
        anchors {
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            bottom: parent.bottom
            bottomMargin: Theme.paddingLarge
        }
        spacing: Theme.paddingLarge

        Label {
            id: timerLabel
            width: parent.width
            wrapMode: Text.WordWrap
            font.bold: true
            opacity: timeoutTimer.running ? 1 : 0
            Behavior on opacity { FadeAnimation { } }

            Timer {
                id: timeoutTimer
                interval: 1000
                triggeredOnStart: true
                repeat: true
                onTriggered: {
                    page.timeoutCountdown -= interval
                    //% "Timeout: %1 seconds"
                    timerLabel.text = qsTrId("csd-la-wifi_timeout_countdown").arg(page.timeoutCountdown/1000)
                    if (page.timeoutCountdown <= 0) {
                        page.state = "done-error-timeout"
                    }
                }
            }
        }

        Button {
            id: restartButton
            x: Theme.paddingLarge
            visible: false
            //% "Restart"
            text: qsTrId("csd-la-restart")
            onClicked: {
                page._restart()
            }
        }
        FailButton {
            id: exitButton
            x: Theme.paddingLarge
            visible: false
            onClicked: {
                page.setTestResult(false)
                testCompleted(true)
            }
        }
    }

    TechnologyModel {
        id: wifiTechModel

        property bool wasInitiallyPowered

        function restoreInitialPoweredState() {
            if (policy.value && powered != wasInitiallyPowered) {
                powered = wasInitiallyPowered
            }
        }

        function _initIfAvailable() {
            if (available) {
                wasInitiallyPowered = powered
                if (powered) {
                    if (page.state == "initializing") {
                        page.state = "scanning"
                    }
                } else if (policy.value) {
                    powered = true
                }
            } else {
                //% "WLAN not available!"
                var statusText = qsTrId("csd-la-status_wlan_not_available")
                statusModel.append({"statusText": statusText, "statusColor": "red"})
                page.state = "done-error"
            }
            mdmBanner.active = available && !powered
            if (mdmBanner.active) {
                page.state = "done-error"
            }
        }

        function _checkCount() {
            if (count > 0 && !triggerPassTimer.running && page.state != "done-success") {
                //% "Networks found, test will pass."
                var statusText = qsTrId("csd-la-status_networks_found")
                statusModel.append({"statusText": statusText, "statusColor": "white"})
                timeoutTimer.stop()
                triggerPassTimer.start()
            }
        }

        name: "wifi"

        Component.onCompleted: {
            _initIfAvailable()
            _checkCount()
        }

        onAvailableChanged: {
            _initIfAvailable()
        }

        onPoweredChanged: {
            if (powered) {
                if (page.state == "initializing") {
                    page.state = "scanning"
                }
            }
            mdmBanner.active = available && !powered
            if (mdmBanner.active) {
                page.state = "done-error"
            }
        }

        onScanRequestFinished: {
            if (page.state == "scanning" && count == 0) {
                //% "No WLAN networks found."
                var statusText = qsTrId("csd-la-status_no_wlan_networks_found")
                statusModel.append({"statusText": statusText, "statusColor": "red"})
                page.state = "done-error"
            }
        }

        onCountChanged: {
            _checkCount()
        }
    }

    Timer {
        id: triggerPassTimer
        interval: 1500
        onTriggered: {
            page.state = "done-success"
        }
    }
}
