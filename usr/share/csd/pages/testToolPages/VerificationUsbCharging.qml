/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Csd 1.0
import Nemo.Mce 1.0
import ".."

CsdTestPage {
    id: page

    property bool completed
    property bool skipped
    property bool isTimeOut

    Column {
        x: Theme.horizontalPageMargin
        width: parent.width - 2*Theme.horizontalPageMargin
        spacing: Theme.paddingLarge

        CsdPageHeader {
            //% "USB Charging"
            title: qsTrId("csd-he-usb_charging")
        }

        Label {
            id: instruction

            visible: !completed

            text: !mceChargerType.connected
                    //% "Please Plug in USB for charging"
                  ? qsTrId("csd-la-please_plug_in_usb_for_charging")
                    //% "Checking. Please wait..."
                  : qsTrId("csd-la-checking_please_wait")
        }

        Label {
            id: description

            width: parent.width
            visible: completed
            wrapMode: Text.Wrap
        }

        ResultLabel {
            id: result

            visible: completed && !skipped
        }
    }

    FailBottomButton {
        visible: !completed

        onClicked: {
            result.result = false
            setTestResult(false)
            testCompleted(true)
        }
    }

    function completeTest(status, text) {
        description.text = text
        if (status === undefined) {
            skipped = true
        } else {
            result.result = status
            setTestResult(result.result)
        }
        testCompleted(false)
        completed = true
        timer.stop()
    }

    function evaluateTestStatus() {
        if (completed) {
            // nop
        } else if (!battery.present()) {
            //% "Battery is not present"
            completeTest(undefined, qsTrId("csd-la-battery_not_present"))
        } else if (!mceChargerType.connected) {
            timer.stop()
        } else if (mceBatteryState.value === MceBatteryState.Full) {
            //% "Battery is full, not charging"
            completeTest(undefined, qsTrId("csd-la-battery_is_full"))
        } else if (mceBatteryState.value === MceBatteryState.Charging) {
            //% "Battery is charging"
            completeTest(true, qsTrId("csd-la-battery_is_charging"))
        } else if (isTimeOut) {
            //% "Battery is not charging"
            completeTest(false, qsTrId("csd-la-battery_is_not_charging"))
        } else {
            timer.start()
        }
    }

    Component.onCompleted: page.evaluateTestStatus()

    Timer {
        id: timer

        interval: 3000
        onTriggered: {
            isTimeOut = true
            page.evaluateTestStatus()
        }
    }

    MceBatteryState {
        id: mceBatteryState

        onValueChanged: page.evaluateTestStatus()
    }

    MceChargerType {
        id: mceChargerType

        readonly property var usbTypes: [ MceChargerType.USB, MceChargerType.DCP, MceChargerType.HVDCP, MceChargerType.CDP ]
        property bool connected: usbTypes.indexOf(type) != -1
        onConnectedChanged: page.evaluateTestStatus()
    }

    Battery {
        id: battery
    }
}
