/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private
import Nemo.DBus 2.0
import ".."

CsdTestPage {
    id: page

    readonly property bool starting: state === "STARTING"
    readonly property bool waiting: state === "WAITING"
    readonly property bool running: starting || waiting

    state: "STARTING"

    onStartingChanged: {
        if (!starting) {
            ipcTimeout.stop()
        }
    }

    onRunningChanged: {
        if (!running) {
            resultTimeout.stop()

            setTestResult(state === "VERIFIED")

            if (isContinueTest) {
                testCompleted(false)
            } else if (state === "STOPPED") {
                testCompleted(true)
            }
        }
    }

    // Pressing on fingerprint sensor doubles as home key and we do
    // not want to background the fingerprint test app due to that
    Private.WindowGestureOverride {
        active: true
    }

    Column {
        width: parent.width
        spacing: Theme.paddingLarge

        CsdPageHeader {
            //% "Fingerprint sensor"
            title: qsTrId("csd-he-fingerprint_sensor")
        }
        DescriptionItem {
            text: {
                if (page.state === "STARTING") {
                    //% "Initiating sensor verification ..."
                    return qsTrId("csd-la-verification_fingerprint_sensor_initialize")
                }
                if (page.state == "IPC_ERROR") {
                    //% "Failure to communicate with fingerprint daemon"
                    return qsTrId("csd-la-verification_fingerprint_sensor_ipc_error")
                }
                if (page.state === "IPC_TIMEOUT") {
                    //% "Timeout while communicating with fingerprint daemon"
                    return qsTrId("csd-la-verification_fingerprint_sensor_ipc_timeout")
                }
                if (page.state === "RESULT_TIMEOUT") {
                    //% "Timeout while waiting for sensor verification result"
                    return qsTrId("csd-la-verification_fingerprint_sensor_result_timeout")
                }
                if (page.state === "VERIFIED") {
                    //% "Fingerprint sensor successfully verified"
                    return qsTrId("csd-la-verification_fingerprint_sensor_success")
                }
                if (page.state === "FAILED") {
                    //% "Fingerprint sensor verification failed"
                    return qsTrId("csd-la-verification_fingerprint_sensor_failure")
                }
                if (page.state === "ABORTED") {
                    //% "Fingerprint sensor verification aborted"
                    return qsTrId("csd-la-verification_fingerprint_sensor_aborted")
                }
                if (page.state === "STOPPED") {
                    //% "Test stopped by user"
                    return qsTrId("csd-la-verification_fingerprint_sensor_stopped")
                }
                // assume "WAITING"
                //% "Place finger on fingerprint sensor in %1 seconds"
                return qsTrId("csd-la-place-finger-on-sensor").arg(countdownTimer.remainingSeconds)
            }
        }
        ResultLabel {
            x: Theme.paddingLarge
            visible: !page.running
            result: page.state === "VERIFIED"
        }
    }

    FailBottomButton {
        visible: page.waiting && !isContinueTest
        onClicked: page.state = "STOPPED"
    }

    DBusInterface {
        id: fpd
        bus: DBus.SystemBus
        service: "org.sailfishos.fingerprint1"
        iface: "org.sailfishos.fingerprint1"
        path: "/org/sailfishos/fingerprint1"
        signalsEnabled: true

        function report(state) {
            if( page.state === "WAITING" ) {
                page.state = state
            }
        }

        function verified() {
            report("VERIFIED")
        }

        function failed() {
            report("FAILED")
        }

        function aborted() {
            report("ABORTED")
        }

        function abort() {
            call("Abort", "")
        }

        function verify() {
            typedCall('Verify', [], function verify_cb(errorcode) {
                if (page.state === "STARTING") {
                    page.state = errorcode ? "IPC_ERROR" : "WAITING"
                }
            })
        }
    }

    Timer {
        // The typedCall() from Nemo.DBus.DBusInterface offers no way
        // to deal with D-Bus error replies. This timer is used as a workaround
        // for dealing with situations such as not having the daemon running.
        id: ipcTimeout
        interval: 2500
        running: true
        onTriggered: page.state = "IPC_TIMEOUT"
    }

    Timer {
        // In any case, do not leave the (potentially non-functioning) test
        // active indefinitely
        id: resultTimeout
        interval: 20000
        running: true
        onTriggered: page.state = "RESULT_TIMEOUT"
    }

    Timer {
        // Provides remaining wait time in seconds for WAITING state
        id: countdownTimer
        property int remainingSeconds: resultTimeout.interval / 1000
        repeat: true
        running: resultTimeout.running
        interval: 1000
        onTriggered: --remainingSeconds
    }

    Component.onCompleted: {
        // Attempt to start sensor verification
        fpd.verify()
    }

    Component.onDestruction: {
        // We can issue an unconditional abort when leaving the
        // context as the daemon will ignore the request unless
        // it is working on something started from this process
        fpd.abort()
    }
}
