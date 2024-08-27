/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.ofono 1.0
import QOfono 0.2
import Csd 1.0
import ".."

AutoTest {
    id: test

    property bool running
    property var modemPassed: []
    property var modems: []
    property var modemsEnabledAtStart
    property bool modemStateSaved
    readonly property bool modemsChecked: modemPassed.length === CsdHwSettings.modemCount

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

    function run() {
        running = true
    }

    function restoreModemState() {
        if (modemStateSaved) {
            modemStateSaved = false
            modemManager.enabledModems = modemsEnabledAtStart
        }
    }

    Component.onDestruction: restoreModemState()

    onModemsCheckedChanged: {
        if (modemsChecked) {
            setTestResult(getResult())
            restoreModemState()
        }
    }

    OfonoModemManager {
        id: modemManager
        onValidChanged: {
            if (!modemStateSaved && modemManager.valid) {
                modemStateSaved = true
                modemsEnabledAtStart = new Array
                for (var i = 0; i < modemManager.enabledModems.length; i++) {
                    modemsEnabledAtStart.push(modemManager.enabledModems[i])
                }
                modemManager.enabledModems = modemManager.availableModems
                var modems = []
                for (i = 0; i < modemManager.availableModems.length; ++i) {
                    var modem = modemTest.createObject(null, {
                                                           "index": i,
                                                           "modemPath": modemManager.availableModems[i]
                                                       })
                    modems.push(modem)
                }
                test.modems = modems

                if (modemManager.availableModems.length === 0) {
                    restoreModemState()
                    setTestResult(false)
                }

                //% "Modem count: %1  (expected: %2)"
                console.log(qsTrId("csd-la-modem_count").arg(modemManager.availableModems.length).arg(CsdHwSettings.modemCount))
            }
        }
    }

    OfonoManager {
        id: ofonoManager
    }

    Timer {
        id: failTimer
        interval: 20000
        running: true
        onTriggered: {
            restoreModemState()
            setTestResult(false)
        }
    }

    Component {
        id: modemTest

        // TODO: Harmonize this Test object between VerificationSim.
        // This provides default properties for QtObject.
        AutoTest {
            id: modemTestItem

            property int index: -1
            readonly property bool passed: ofonoModem.passed && ofonoSimManager.passed
            readonly property alias resultText: ofonoSimManager.resultText
            property alias modemPath: ofonoModem.modemPath

            onPassedChanged: {
                var modemPassed = test.modemPassed
                modemPassed[index] = passed
                test.modemPassed = modemPassed
                failTimer.stop()
            }

            Timer {
                id: failTimer
                interval: 20000
                running: true
                onTriggered: {
                    ofonoSimManager.passed = false
                    ofonoSimManager.passedChanged()
                }
            }

            OfonoModem {
                id: ofonoModem
                property bool passed: valid && serial !== ""
            }

            OfonoSimManager {
                id: ofonoSimManager

                property bool passed: valid && present && cardIdentifier !== ""
                                      && mobileCountryCode !== "" && mobileNetworkCode !== ""
                                      && subscriberIdentity !== ""
                readonly property string resultText: {
                    if (!present) {
                        //% "Cellular modem is not available"
                        return qsTrId("csd-la-cellular_modem_unavailable")
                    } else if (cardIdentifier === "") {
                        //% "Invalid card identifier"
                        return qsTrId("csd-la-invalid_card_identifier")
                    } else if (mobileCountryCode === "") {
                        //% "Invalid MCC"
                        return qsTrId("csd-la-invalid_mcc")
                    } else if (mobileNetworkCode === "") {
                        //% "Invalid MNC"
                        return qsTrId("csd-la-invalid_mnc")
                    } else if (subscriberIdentity === "") {
                        //% "Invalid subscriber identity"
                        return qsTrId("csd-la-invalid_subscriber_identity")
                    } else {
                        return ""
                    }
                }

                modemPath: ofonoModem.modemPath
            }
        }
    }
}
