/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.ofono 1.0
import MeeGo.QOfono 0.2
import Csd 1.0
import ".."

CsdTestPage {
    id: page

    property var modemPassed: []
    property var modemsEnabledAtStart
    property bool modemStateSaved

    OfonoModemManager {
        id: modemManager
        onValidChanged: saveModemState()
    }

    OfonoManager {
        id: ofonoManager
    }

    onModemPassedChanged: {
        if (modemPassed.length === CsdHwSettings.modemCount) {
            failTimer.stop()
            setTestResult(getResult())
            testCompleted(false)
        }
    }

    function saveModemState() {
        if (!modemStateSaved && modemManager.valid) {
            modemStateSaved = true
            modemsEnabledAtStart = new Array
            for (var i = 0; i < modemManager.enabledModems.length; i++) {
                modemsEnabledAtStart.push(modemManager.enabledModems[i])
            }
            modemManager.enabledModems = modemManager.availableModems
            simList.model = modemManager.availableModems
        }
    }

    function restoreModemState() {
        if (modemStateSaved) {
            modemStateSaved = false
            modemManager.enabledModems = modemsEnabledAtStart
        }
    }

    Component.onDestruction: restoreModemState()

    onStatusChanged: {
        if (status === PageStatus.Activating) {
            saveModemState()
        } else if (status === PageStatus.Inactive) {
            restoreModemState()
        }
    }

    function getResult() {
        if (ofonoManager.modems.length === CsdHwSettings.modemCount &&
            ofonoManager.modems.length === modemPassed.length) {
            for (var i = 0; i < modemPassed.length; ++i) {
                if (!modemPassed[i]) {
                    return false
                }
            }
            return true
        }
        return false
    }

    Timer {
        id: failTimer
        interval: 20000
        running: true
        onTriggered: {
            setTestResult(getResult())
            testCompleted(false)
        }
    }

    Timer {
        id: startTimer
        interval: 2000
        running: true
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        VerticalScrollDecorator {}

        Column {
            id: content
            width: page.width
            spacing: Theme.paddingLarge

            CsdPageHeader {
                //% "SIM"
                title: qsTrId("csd-he-sim")
            }

            Item {
                id: resultsItem
                x: Theme.paddingLarge
                width: parent.width - 2*Theme.paddingLarge
                height: resultLabel.implicitHeight
                property bool busy: startTimer.running || (failTimer.running && !resultLabel.result)

                BusyIndicator {
                    anchors.verticalCenter: parent.verticalCenter
                    size: BusyIndicatorSize.Small
                    running: resultsItem.busy
                }

                ResultLabel {
                    id: resultLabel
                    anchors.verticalCenter: parent.verticalCenter
                    result: modemPassed.length === CsdHwSettings.modemCount && getResult()
                    opacity: resultsItem.busy ? 0 : 1
                    Behavior on opacity { FadeAnimation {}}
                }
            }

            Label {
                x: Theme.paddingLarge
                //% "Modem count: %1  (expected: %2)"
                text: qsTrId("csd-la-modem_count").arg(ofonoManager.modems.length).arg(CsdHwSettings.modemCount)
            }

            Repeater {
                id: simList
                delegate: modemTest
            }
        }
    }

    Component {
        id: modemTest

        Column {
            width: page.width
            spacing: Theme.paddingMedium

            property bool simPresent: ofonoSimManager.valid && ofonoSimManager.present
            readonly property bool isPinRequired: ofonoSimManager.pinRequired !== OfonoSimManager.NoPin
            property bool passed: ofonoModem.passed && ofonoSimManager.passed

            function updateResult(passed) {
                var modemPassed = page.modemPassed
                modemPassed[index] = passed
                page.modemPassed = modemPassed
                modemFailTimer.stop()
                // Stop global fail timer if a modem is failed.
                if (!passed) {
                    failTimer.stop()
                }
            }

            onPassedChanged: updateResult(passed)

            OfonoModem {
                id: ofonoModem
                modemPath: modelData
                property bool passed: valid && serial !== ""
                onPassedChanged: modemFailTimer.running = true
            }

            OfonoSimManager {
                id: ofonoSimManager
                modemPath: modelData
                property bool passed: valid && present && cardIdentifier !== ""
                                      && (mobileCountryCode !== "" && mobileNetworkCode !== ""
                                          && subscriberIdentity !== ""
                                          || isPinRequired)
                onValidChanged: modemFailTimer.start()
            }

            // Give SimManager up to five seconds figure if SIM is present and read IMSI and other
            // stuff from the SIM. If it takes longer, indicate failure
            Timer {
                id: modemFailTimer
                interval: 5000
                onTriggered: {
                    ofonoSimManager.passed = false
                    updateResult(false)
                }
            }

            SectionHeader {
                visible: CsdHwSettings.modemCount > 1
                //% "SIM: %1"
                text: qsTrId("csd-la-sim-number").arg(index+1)
            }

            Label {
                x: Theme.paddingLarge
                text: {
                    var available
                    if (ofonoModem.valid) {
                        //% "true"
                        available = qsTrId("csd-la-true")
                    } else {
                        //% "false"
                        available = qsTrId("csd-la-false")
                    }

                    //% "Cellular modem available: %1"
                    return qsTrId("csd-la-cellular_modem_available").arg(available)
                }
            }

            Label {
                x: Theme.paddingLarge
                //% "Modem serial: %1"
                text: qsTrId("csd-la-cellular_modem_serial").arg(ofonoModem.valid ? ofonoModem.serial : "")
            }

            Label {
                x: Theme.paddingLarge
                text: {
                    var present
                    if (ofonoSimManager.present) {
                        //% "true"
                        present = qsTrId("csd-la-true")
                    } else {
                        //% "false"
                        present = qsTrId("csd-la-false")
                    }

                    //% "SIM present: %1"
                    return qsTrId("csd-la-sim_present").arg(present)
                }
            }

            Label {
                visible: simPresent
                x: Theme.paddingLarge
                //% "Card identifier: %1"
                text: qsTrId("csd-la-card_identifier").arg(ofonoSimManager.cardIdentifier)
            }

            Label {
                visible: simPresent && !isPinRequired
                x: Theme.paddingLarge
                //% "MCC: %1"
                text: qsTrId("csd-la-mcc").arg(ofonoSimManager.mobileCountryCode)
            }

            Label {
                visible: simPresent && !isPinRequired
                x: Theme.paddingLarge
                //% "MNC: %1"
                text: qsTrId("csd-la-mnc").arg(ofonoSimManager.mobileNetworkCode)
            }

            Label {
                visible: simPresent && !isPinRequired
                x: Theme.paddingLarge
                //% "Subscriber identity: %1"
                text: qsTrId("csd-la-subscriber_identity").arg(ofonoSimManager.subscriberIdentity)
            }

            Label {
                visible: simPresent && !isPinRequired
                x: Theme.paddingLarge
                //% "Subscriber numbers: %1"
                text: qsTrId("csd-la-subscriber_numbers").arg(ofonoSimManager.subscriberNumbers.length > 0 ? ofonoSimManager.subscriberNumbers.join(", ") : 'N/A')
            }

            Label {
                x: Theme.paddingLarge
                width: parent.width - 2*Theme.paddingLarge
                wrapMode: Text.Wrap
                visible: !ofonoSimManager.passed || isPinRequired
                text: {
                    if (!ofonoSimManager.present) {
                        //% "Cellular modem is not available"
                        return qsTrId("csd-la-cellular_modem_unavailable")
                    } else if (ofonoSimManager.cardIdentifier === "") {
                        //% "Invalid card identifier"
                        return qsTrId("csd-la-invalid_card_identifier")
                    } else if (isPinRequired) {
                        //: "Because the requested PIN code wasn't entered during boot, fields MCC, MNC, Subscriber identity and numbers won't be visible"
                        //% "PIN not entered, some fields unavailable"
                        return qsTrId("csd-la-pin_code_not_entered")
                    } else if (ofonoSimManager.mobileCountryCode === "") {
                        //% "Invalid MCC"
                        return qsTrId("csd-la-invalid_mcc")
                    } else if (ofonoSimManager.mobileNetworkCode === "") {
                        //% "Invalid MNC"
                        return qsTrId("csd-la-invalid_mnc")
                    } else if (ofonoSimManager.subscriberIdentity === "") {
                        //% "Invalid subscriber identity"
                        return qsTrId("csd-la-invalid_subscriber_identity")
                    } else {
                        return ""
                    }
                }
            }
        }
    }
}
