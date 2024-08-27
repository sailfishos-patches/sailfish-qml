/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Bluetooth 1.0
import org.kde.bluezqt 1.0 as BluezQt
import com.jolla.settings 1.0
import ".."

CsdTestPage {
    id: page

    property int timeout: 30 * 1000
    property int timeoutCountdown

    function _start() {
        if (bluetoothTechModel.available && picker.adapter != null && picker.adapter != undefined) {
            bluetoothTechModel.reset()
            statusModel.clear()
            _restartTimeout()
            page.state = "initializing"
            picker.autoStartDiscovery = true
            picker.startDiscovery()
        } else {
            page.state = "done-error"
        }
    }

    function _restart() {
        picker.stopDiscovery()
        page.state = ""
        _start()
    }

    function _restartTimeout() {
        timeoutCountdown = timeout
        timeoutTimer.restart()
    }

    onStatusChanged: {
        if (status == PageStatus.Active && state == "") {
            _start()
        }
    }

    onStateChanged: {
        console.log("Bluetooth test state:", state)
    }

    onPageContainerChanged: {
        if (pageContainer == null) {    // page was popped
            bluetoothTechModel.restoreInitialPoweredState()
        }
    }

    states: [
        State {
            name: "initializing"
            StateChangeScript {
                script: {
                    //% "Turning Bluetooth on..."
                    var statusText = qsTrId("csd-la-status_power_on_bluetooth")
                    statusModel.append({"statusText": statusText, "statusColor": "white"})
                }
            }
        },
        State {
            name: "done-success"
            StateChangeScript {
                script: {
                    //% "Test passed."
                    var statusText = qsTrId("csd-la-bluetooth_status_pass")
                    statusModel.append({"statusText": statusText, "statusColor": "green"})
                }
            }
        },
        State {
            name: "done-error"
            PropertyChanges { target: restartButton; visible: true }
            PropertyChanges { target: exitButton; visible: !page.isContinueTest }
            StateChangeScript {
                script: {
                    //% "Bluetooth not available!"
                    var errorStatus = qsTrId("csd-la-status_bluetooth_not_available")
                    statusModel.append({"statusText": errorStatus, "statusColor": "red"})
                }
            }
        },
        State {
            name: "done-error-timeout"
            StateChangeScript {
                script: {
                    //% "Error: test timed out!"
                    var errorStatus = qsTrId("csd-la-status_bluetooth_timeout")
                    statusModel.append({"statusText": errorStatus, "statusColor": "red"})
                }
            }
        }
    ]

    CsdPageHeader {
        id: header
        //% "Bluetooth"
        title: qsTrId("csd-he-bluetooth")
    }

    Column {
        id: col
        anchors.top: header.bottom
        width: page.width
        height: parent.height - header.height - (buttonSet.height + buttonSet.anchors.bottomMargin)
        spacing: Theme.paddingLarge

        Column {
            id: topInfoColumn
            width: parent.width
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                wrapMode: Text.Wrap
                font.bold: true

                //% "Status:"
                text: qsTrId("csd-la-status_bluetooth")
            }
            Repeater {
                model: ListModel { id: statusModel }
                delegate: Label {
                    x: Theme.horizontalPageMargin
                    width: topInfoColumn.width - 2*x
                    wrapMode: Text.Wrap
                    color: model.statusColor
                    font.bold: true
                    text: model.statusText
                }
            }
        }

        SilicaFlickable {
            id: results
            width: parent.width
            height: parent.height - topInfoColumn.height
            contentHeight: picker.height
            clip: true

            VerticalScrollDecorator {
                Component.onCompleted: showDecorator()
            }

            BluetoothDevicePicker {
                id: picker

                property bool wasInitiallyPowered

                highlightSelectedDevice: false
                showPairedDevicesHeader: true
                autoStartDiscovery: true

                onDiscoveringChanged: {
                    if (discovering && page.state == "initializing") {
                        //% "Searching for nearby devices..."
                        var statusText = qsTrId("csd-la-status_searching_nearby_devices")
                        statusModel.append({"statusText": statusText, "statusColor": "white"})
                        page.state = "discovering"
                    } else if (!discovering && timeoutTimer.running) {
                        picker.startDiscovery()
                    }
                }

                Connections {
                    target: picker.adapter
                    onPoweredChanged: {
                        // Keep adapter powered
                        if (timeoutTimer.running && !picker.adapter.powered) {
                            picker.adapter.powered = true
                            picker.startDiscovery()
                        }
                    }
                }

                // BluetoothDevicePicker only tells us if any devices are displayed (including
                // paired devices) so need BluezQt.Manager to find out if any devices
                // have been found nearby.
                Connections {
                    target: BluezQt.Manager
                    onDeviceAdded: {
                        console.log("Bluetooth device found:", device.address)
                        // Mark test as passed when one device is found.
                        if ((page.state == "discovering" || picker.discovering)
                                && !bluetoothTechModel.testFinished) {
                            //% "Devices found, test will pass."
                            var statusText = qsTrId("csd-la-status_discovery_successful")
                            statusModel.append({"statusText": statusText, "statusColor": "white"})
                            bluetoothTechModel.done(true)
                        }
                    }
                }

                Component.onDestruction: {
                    stopDiscovery()
                    bluetoothTechModel.powered = picker.wasInitiallyPowered
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
            wrapMode: Text.Wrap
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
                        bluetoothTechModel.done(false)
                    }
                }
            }
        }

        Button {
            id: restartButton
            visible: false
            //% "Restart"
            text: qsTrId("csd-la-restart")
            onClicked: {
                page._restart()
            }
        }
        FailButton {
            id: exitButton
            visible: false
            onClicked: {
                page.setTestResult(false)
                testCompleted(true)
            }
        }
    }

    VerificationTechnologyModel {
        id: bluetoothTechModel

        name: "bluetooth"
        onFinished: {
            if (!success && picker.empty) {
                //% "No Bluetooth devices found nearby."
                var errorStatus = qsTrId("csd-la-status_no_bluetooth_devices_nearby")
                statusModel.append({"statusText": errorStatus, "statusColor": "red"})
            }

            page.state = success ? "done-success" : "done-error"
            page.setTestResult(success)
            testCompleted(false)
            timeoutTimer.stop()
        }

        onAvailableChanged: {
            picker.wasInitiallyPowered = bluetoothTechModel.wasInitiallyPowered
            page._restart()
        }
        Component.onCompleted: initTestCase()
    }
}
