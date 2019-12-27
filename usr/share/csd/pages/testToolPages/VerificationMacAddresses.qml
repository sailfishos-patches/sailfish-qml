/*
 * Copyright (c) 2018 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Csd 1.0
import ".."

CsdTestPage {
    id: page

    function allMacsOk() {
        return macValidator.isMacValid("bluetooth") && macValidator.isMacValid("wireless")
    }

    Component.onDestruction: {
        page.setTestResult(allMacsOk())
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

            result: allMacsOk()
        }

        SectionHeader {
            //% "Wireless MAC"
            text: qsTrId("csd-he-wireless-mac")
        }

        Label {
            x: Theme.paddingLarge
            width: page.width - (2 * Theme.paddingLarge)
            wrapMode: Text.Wrap

            color: macValidator.isMacValid("wireless")
                   ? "green"
                   : "red"

            text: macValidator.isMacValid("wireless")
                    //% "Test passed."
                    ? qsTrId("csd-la-test-passed")
                    //% "Test failed."
                    : qsTrId("csd-la-test-failed")
        }

        Label {
            x: Theme.paddingLarge
            width: page.width - (2 * Theme.paddingLarge)
            wrapMode: Text.Wrap

            //% "Value: %1"
            text: qsTrId("csd-la-value").arg(macValidator.getMac("wireless"))
        }

        Label {
            x: Theme.paddingLarge
            width: page.width - (2 * Theme.paddingLarge)
            fontSizeMode: Text.HorizontalFit

            visible: !macValidator.isMacValid("wireless")

            //% "Acceptance criteria: %1"
            text: qsTrId("csd-la-acceptance-criteria").arg(macValidator.getMacCriteria("wireless"))
        }

        SectionHeader {
            //% "Bluetooth MAC"
            text: qsTrId("csd-he-bluetooth-mac")
        }

        Label {
            x: Theme.paddingLarge
            width: page.width - (2 * Theme.paddingLarge)
            wrapMode: Text.Wrap

            color: macValidator.isMacValid("bluetooth")
                   ? "green"
                   : "red"

            text: macValidator.isMacValid("bluetooth")
                    //% "Test passed."
                    ? qsTrId("csd-la-test-passed")
                    //% "Test failed."
                    : qsTrId("csd-la-test-failed")
        }

        Label {
            x: Theme.paddingLarge
            width: page.width - (2 * Theme.paddingLarge)
            wrapMode: Text.Wrap

            //% "Value: %1"
            text: qsTrId("csd-la-value").arg(macValidator.getMac("bluetooth"))
        }

        Label {
            x: Theme.paddingLarge
            width: page.width - (2 * Theme.paddingLarge)
            fontSizeMode: Text.HorizontalFit

            visible: !macValidator.isMacValid("bluetooth")

            //% "Acceptance criteria: %1"
            text: qsTrId("csd-la-acceptance-criteria").arg(macValidator.getMacCriteria("bluetooth"))
        }
    }

    MacValidator {
        id: macValidator
    }
}

