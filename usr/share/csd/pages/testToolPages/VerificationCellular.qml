/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import MeeGo.QOfono 0.2
import org.nemomobile.ofono 1.0

AllModemsPage {
    id: page

    property alias pageTitle: header.title
    property string testTechnology
    property bool requireAllModems

    property int techCount
    property bool testOK: presentSimCount > 0 &&
                          techCount === (requireAllModems ? presentSimCount : 1)

    onTestOKChanged: {
        setTestResult(testOK)
        testCompleted(false)
    }

    function updateTechCount() {
        var count = 0
        for (var i = 0; i<availableModems.length; i++) {
            if (simList.itemAt(i).technology === testTechnology) {
                count++
            }
        }
        techCount = count
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
                id: header
            }

            Item {
                id: resultsItem
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                height: resultLabel.implicitHeight
                property bool busy: failTimerRunning && !testOK

                BusyIndicator {
                    anchors.verticalCenter: parent.verticalCenter
                    size: BusyIndicatorSize.Small
                    running: resultsItem.busy
                }

                ResultLabel {
                    id: resultLabel
                    anchors.verticalCenter: parent.verticalCenter
                    result: testOK
                    opacity: resultsItem.busy ? 0 : 1
                    Behavior on opacity { FadeAnimation {}}
                }
            }

            Repeater {
                id: simList
                model: availableModems
                delegate: modemTest
            }
        }
    }

    Component {
        id: modemTest

        Column {
            id: column
            x: Theme.horizontalPageMargin
            width: parent.width - x*2
            spacing: Theme.paddingLarge
            property alias technology: ofonoNetworkRegistration.technology
            property alias simPresent: ofonoSimManager.simPresent
            property alias registered: ofonoNetworkRegistration.registered

            OfonoSimManager {
                id: ofonoSimManager
                modemPath: modelData
                property bool simPresent: valid && present
            }

            OfonoRadioSettings {
                property string savedTechnologyPreference
                id: ofonoRadioSettings
                modemPath: modelData
                onValidChanged: {
                    if (valid && !savedTechnologyPreference) {
                        savedTechnologyPreference = technologyPreference
                        technologyPreference = testTechnology
                    }
                }
                Component.onDestruction: {
                    if (savedTechnologyPreference) {
                        technologyPreference = savedTechnologyPreference
                    }
                }
            }

            OfonoNetworkRegistration {
                id: ofonoNetworkRegistration
                modemPath: modelData
                property bool registered: valid && (status === "registered" || status === "roaming")
                onTechnologyChanged: updateTechCount()
            }

            SectionHeader {
                x: 0
                width: parent.width
                visible: availableModems.length > 1
                //% "SIM: %1"
                text: qsTrId("csd-la-sim-number").arg(index+1)
            }

            Label {
                width: parent.width
                //% "SIM present: %1"
                text: qsTrId("csd-la-sim_present").arg(simPresent ?
                      //% "true"
                      qsTrId("csd-la-true") :
                      //% "false"
                      qsTrId("csd-la-false"))
            }

            Label {
                width: parent.width
                visible: simPresent
                //% "Network status: %1"
                text: qsTrId("csd-la-network_status").arg(ofonoNetworkRegistration.status)
            }

            Label {
                width: parent.width
                visible: simPresent && registered
                //% "Technology: %1"
                text: qsTrId("csd-la-cellular_technology").arg(ofonoNetworkRegistration.technology)
            }

            Label {
                width: parent.width
                visible: simPresent && registered
                //% "Cell ID: %1"
                text: qsTrId("csd-la-cell_id").arg(ofonoNetworkRegistration.cellId ? ofonoNetworkRegistration.cellId : "")
            }

            Label {
                width: parent.width
                visible: simPresent && registered
                //% "Signal strength: %1"
                text: qsTrId("csd-la-signal_strength").arg(ofonoNetworkRegistration.strength ? (ofonoNetworkRegistration.strength + "%") : "")
            }
        }
    }
}
