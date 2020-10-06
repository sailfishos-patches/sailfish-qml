/*
 * Copyright (c) 2020 Open Mobile Platform LLC
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
    
    property bool initialNfcState
    property int touchCounter
    property int passCriteria: 3

    NfcSettings {
        id: nfcSettings

        onValidChanged: {
            if (valid) {
                initialNfcState = nfcSettings.enabled
                if (!initialNfcState)
                    nfcSettings.enabled = true
            }
        }
    }

    Column {
        width: page.width

        CsdPageHeader {
            //% "NFC"
            title: qsTrId("csd-he-nfc")
        }

        DescriptionItem {
            //% "Touch NFC tag %n times"
            text: qsTrId("csd-la-verification_nfc_description", passCriteria)
        }

        Label {
            x: Theme.paddingLarge
            width: page.width - (2 * Theme.paddingLarge)
            wrapMode: Text.Wrap            
            text: {
                switch (nfc.adapterStatus) {

                case Nfc.AdapterStatusUnknown:
                    //% "NFC adapter not initialized"
                    return qsTrId("csd-la-nfc-adapter-not-initialized")
                case Nfc.AdapterStatusNotFound:
                    //% "NFC adapter not found"
                    return qsTrId("csd-la-nfc-adapter-not-found")
                case Nfc.AdapterStatusFound:
                    //% "NFC adapter found"
                    return qsTrId("csd-la-fc-adapter-found")
                default:
                    //% "NFC adapter undefined"
                    return qsTrId("csd-la-fc-adapter-undefined")
                }
            }
        }

        Label {
            visible: nfc.adapterStatus == Nfc.AdapterStatusFound
            x: Theme.paddingLarge
            width: page.width - (2 * Theme.paddingLarge)
            wrapMode: Text.Wrap            
            //% "Touch count: %n"
            text: qsTrId("csd-la-nfc_counter", touchCounter)
        }

        ResultLabel {
            id: passText
            x: Theme.paddingLarge
            visible: nfc.passed
            result: true
        }
    }

    FailBottomButton {
        id: failButton
        visible: !nfc.passed
        onClicked: {
            setTestResult(false)
            testCompleted(false)
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Deactivating) 
            nfcSettings.enabled = initialNfcState
    }

    Nfc {
        id: nfc

        onTouchDetected: touchCounter++
        readonly property bool passed: touchCounter >= passCriteria
        onPassedChanged: check()

        function check() {
            setTestResult(nfc.passed)
            testCompleted(false)
            failButton.visible = false
            passText.visible = true
        }
    }
}
