/*
 * Copyright (c) 2016 - 2023 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Settings.Networking 1.0
import QOfono 0.2
import Nemo.Connectivity 1.0

Column {
    id: root

    property string modemPath
    property var simManager

    property string _statusText: {
        if (!simManager.modemHasPresentSim(modemPath)) {
            return "no-sim"
        }

        switch (networkStatusIndicator.networkRegistration.status) {
        case "unregistered":
            return "disabled"
        case "registered":
            return "home"
        case "searching":
        case "unknown":
            return "offline"
        case "denied":
            return "forbidden"
        case "roaming":
            return "roam"
        default:
            return ""
        }
    }

    Row {
        spacing: Theme.paddingMedium
        CheckLabel {
            checked: networkStatusIndicator.networkRegistration.status !== "unregistered"
            //% "Enabled"
            text: qsTrId("csd-la-enabled")
        }
        CheckLabel {
            checked: mobileData.valid && mobileData.autoConnect

            //% "Data"
            text: qsTrId("csd-la-data")
        }
        Label { text: "Reg: %1".arg(root._statusText) }

        Row {
            spacing: Theme.paddingSmall

            Label {
                text: {
                    var val = networkStatusIndicator.networkRegistration.technology
                    if (val.length && val !== 'unknown') {
                        var techToG = {gsm: "2", edge: "2.5", umts: "3", hspa: "3.5", lte: "4", nr: "5"}
                        return techToG[val] + "G"
                    }
                    return ""
                }
            }

            MobileNetworkStatusIndicator {
                id: networkStatusIndicator

                anchors.verticalCenter: parent.verticalCenter
                modemPath: root.modemPath
                simManager: root.simManager
            }

            Label { text: networkStatusIndicator.networkRegistration.strength || "" }
        }
    }

    MobileDataConnection {
        id: mobileData

        modemPath: root.modemPath
    }
}
