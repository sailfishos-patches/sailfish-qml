/*
 * Copyright (c) 2018 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Csd 1.0
import ".."

CsdTestPage {
    id: page

    property bool wlanSupported: Features.supported("Wifi")
    property bool bluetoothSupported: Features.supported("Bluetooth")

    property string wlanMac: wlanSupported ? aboutSettings.wlanMacAddress : ""
    property string bluetoothMac: bluetoothSupported ? macValidator.getMac("bluetooth") : ""

    property bool wlanValid: !wlanSupported || macValidator.isMacValid("wireless", wlanMac)
    property bool bluetoothValid: !bluetoothSupported || macValidator.isMacValid("bluetooth", bluetoothMac)

    property bool allMacsOk: wlanValid && bluetoothValid

    Component.onDestruction: {
        page.setTestResult(allMacsOk)
        testCompleted(false)
    }

    Column {
        CsdPageHeader {
            //% "MAC Addresses"
            title: qsTrId("csd-he-mac-addresses")
        }

        ResultLabel {
            id: testResult

            x: Theme.horizontalPageMargin
            width: parent.width - 2*x

            result: allMacsOk
        }

        SectionHeader {
            //% "Wireless MAC"
            text: qsTrId("csd-he-wireless-mac")
            visible: wlanSupported
        }

        Label {
            x: Theme.paddingLarge
            width: page.width - (2 * Theme.paddingLarge)
            wrapMode: Text.Wrap
            visible: wlanSupported

            color: wlanValid
                   ? "green"
                   : "red"

            text: wlanValid
                    //% "Test passed."
                    ? qsTrId("csd-la-test-passed")
                    //% "Test failed."
                    : qsTrId("csd-la-test-failed")
        }

        Label {
            x: Theme.paddingLarge
            width: page.width - (2 * Theme.paddingLarge)
            wrapMode: Text.Wrap
            visible: wlanSupported

            //% "Value: %1"
            text: qsTrId("csd-la-value").arg(wlanMac)
        }

        Label {
            x: Theme.paddingLarge
            width: page.width - (2 * Theme.paddingLarge)
            fontSizeMode: Text.HorizontalFit

            visible: !wlanValid

            //% "Acceptance criteria: %1"
            text: qsTrId("csd-la-acceptance-criteria").arg(macValidator.getMacCriteria("wireless"))
        }

        SectionHeader {
            //% "Bluetooth MAC"
            text: qsTrId("csd-he-bluetooth-mac")
            visible: bluetoothSupported
        }

        Label {
            x: Theme.paddingLarge
            width: page.width - (2 * Theme.paddingLarge)
            wrapMode: Text.Wrap
            visible: bluetoothSupported

            color: bluetoothValid
                   ? "green"
                   : "red"

            text: bluetoothValid
                    //% "Test passed."
                    ? qsTrId("csd-la-test-passed")
                    //% "Test failed."
                    : qsTrId("csd-la-test-failed")
        }

        Label {
            x: Theme.paddingLarge
            width: page.width - (2 * Theme.paddingLarge)
            wrapMode: Text.Wrap
            visible: bluetoothSupported

            //% "Value: %1"
            text: qsTrId("csd-la-value").arg(bluetoothMac)
        }

        Label {
            x: Theme.paddingLarge
            width: page.width - (2 * Theme.paddingLarge)
            fontSizeMode: Text.HorizontalFit

            visible: !bluetoothValid

            //% "Acceptance criteria: %1"
            text: qsTrId("csd-la-acceptance-criteria").arg(macValidator.getMacCriteria("bluetooth"))
        }
    }

    AboutSettings {
        id: aboutSettings
    }

    MacValidator {
        id: macValidator
    }
}

